# frozen_string_literal: true

require "json"
require "net/http"
require "big_commerce/management_api/version"

module BigCommerce
  module ManagementAPI
    Error = Class.new(StandardError)

    class ResponseHeaders
      def initialize(headers)
        @headers = headers || {}
      end

      def [](name)
        @headers[name]
      end

      def request_id
        value = @headers["x-request-id"]
        value.is_a?(Array) ? value[0] : value
      end

      %w[x-rate-limit-requests-left
         x-rate-limit-time-reset-ms
         x-rate-limit-requests-quota
         x-rate-limit-time-window-ms].each do |header|

        method = header.delete_prefix("x-")
        method.tr!("-", "_")

        define_method(method) do
          value = @headers[header]
          # Net::HTTP returns as an array
          (value.is_a?(Array) ? value[0] : value).to_i
        end
      end
    end

    class ResponseError < Error
      attr_reader :headers

      def initialize(data, headers)
        @headers = ResponseHeaders.new(headers)
        @data = data

        super error_message(data)
      end

      private

      def error_message(data)
        #
        # Looks for a structure like one of these  and picks best message:
        #
        # A:
        #
        # {"errors"=>
        #   [{"status"=>409,
        #     "title"=>"Cannot have multiple segments with the same name",
        #     "type"=>
        #      "https://developer.bigcommerce.com/api-docs/getting-started/api-status-codes",
        #     "errors"=>{}}]
        #
        #
        # B:
        #
        # {"status"=>422,
        #  "title"=>"Set customer attribute values failed.",
        #  "type"=>
        #   "https://developer.bigcommerce.com/api-docs/getting-started/api-status-codes",
        #  "errors"=>{"0.data"=>"missing attribute value"}}
        #
        return data unless data.is_a?(Hash)

        data = data["errors"][0] if data["errors"].is_a?(Array)

        if data["errors"].any?
          errors = data["errors"].map { |property, message| "#{property}: #{message.chomp(".")}" }
          errors.join(", ")
        else
          title = data["title"].chomp(".")
          sprintf("%s (%s)", title, data["status"])
        end
      end
    end

    class Endpoint
      HOST = "api.bigcommerce.com"
      PORT = 443

      USER_AGENT = "BigCommerce Management API Client v#{BigCommerce::ManagementAPI::VERSION} (Ruby v#{RUBY_VERSION})"

      CONTENT_TYPE = "Content-Type"
      CONTENT_TYPE_JSON = "application/json"

      JSON_CONTENT_TYPES = [CONTENT_TYPE_JSON, "application/problem+json"].freeze

      RESULT_KEY = "data"

      # May go in its own file
      class Response
        include Enumerable

        # class Pagination
        class2 self,
               :pagination => {
                 :total => 0,
                 :count => 0,
                 :per_page => 0,
                 :current_page => 0,
                 :total_pages => 0,
                 :links => {
                   :previous => "string",
                   :current => "string",
                   :next => "string"
                 }
               }

        class Meta
          attr_reader :pagination, :total, :success, :failed

          def initialize(meta)
            @total = meta["total"]
            @success = meta["success"]
            @failed = meta["failed"]

            @pagination = Pagination.new(meta["pagination"]) if meta["pagination"]
          end
        end

        attr_reader :meta, :headers

        def initialize(headers, result = nil, meta = nil)
          @result = result || []
          @headers = ResponseHeaders.new(headers)
          @meta = Meta.new(meta) if meta
        end

        def each(&block)
          @result.each(&block)
        end
      end

      def initialize(store_hash, auth_token, options = nil)
        raise ArgumentError, "store hash required" if store_hash.to_s.empty?
        raise ArgumentError, "auth token required" if auth_token.to_s.empty?

        @store_hash = store_hash
        @auth_token = auth_token
        @options = options || {}
      end

      protected

      def DELETE(path, data = {})
        path = endpoint(path)
        path << query_string(data) if data && data.any?

        request(Net::HTTP::Delete.new(path), data)
      end

      def GET(path, data = {})
        path = endpoint(path)
        path << query_string(data) if data && data.any?

        request(Net::HTTP::Get.new(path), data)
      end

      def POST(path, data = {})
        request(Net::HTTP::Post.new(endpoint(path)), data)
      end

      def PUT(path, data = {})
        request(Net::HTTP::Put.new(endpoint(path)), data)
      end

      # For better or worse all Response instances contain an Array
      # In some cases we don't want this since response only contains a single result
      def unwrap(result)
        record = result.first
        return unless record

        record.meta = result.meta
        record.headers = result.headers
        record
      end

      def with_in_param(options, *param_names)
        return unless options

        options = options.dup
        options.keys.each do |name|
          # Remove optional ":in" portion from "id:in" which may or may not be a Symbol
          name = name.to_s.split(":")[0].to_sym
          next unless param_names.include?(name)

          values = Array(options.delete(name))

          in_name = "#{name}:in"
          values.concat(Array(options.delete(in_name)))

          next unless values.any?

          options[in_name] = values
        end

        options
      end

      private

      def query_string(params)
        query = []

        # We do this manually to join arrays and because time cannot be escaped as it will not be properly applied server-side
        params.each do |name, value|
          name = URI.encode_www_form_component(name)

          if value.is_a?(Array)
            value = value.join(",")
          elsif value.respond_to?(:strftime)
            value = value.strftime("%Y-%m-%dT%H:%M:%S%z")
          else
            value = URI.encode_www_form_component(value)
          end

          query << "#{name}=#{value}"
        end

        sprintf("?%s", query.join("&"))
      end

      def endpoint(path)
        sprintf("/stores/%s/v3/%s", @store_hash, path)
      end

      # TODO: move this to request() so we can create ResponseError
      def parse_json(s)
        JSON.parse(s)
      rescue JSON::ParserError => e
        raise Error, "failed to parse response JSON: #{e}"
      end

      def request(req, data = {})
        req["X-Auth-Token"] = @auth_token
        req["User-Agent"] = USER_AGENT

        if req.request_body_permitted? && data && data.any?
          req.body = data.to_json
          req[CONTENT_TYPE] = CONTENT_TYPE_JSON
        end

        request = Net::HTTP.new(HOST, PORT)
        request.use_ssl = true

        if !@options[:debug]
         request.set_debug_output(nil)
        else
          request.set_debug_output(
            @options[:debug].is_a?(IO) ? @options[:debug] : $stderr
          )
        end

        request.start { |http| handle_response(http.request(req)) }
      end

      def handle_response(res)
        # TODO: data can be HTML string! Don't want this in the error! Do we?
        data = res.body && JSON_CONTENT_TYPES.include?(res[CONTENT_TYPE]) ? parse_json(res.body) : res.body
        # pp data
        # Otherwise only available by name via #[]
        headers = res.to_hash

        raise ResponseError.new(data, headers) if res.code[0] != "2"

        # 204, likely
        return Response.new(headers) unless data

        result = data[self.class::RESULT_KEY]
        if result.is_a?(Array)
          result.map! { |data| self.class::RESULT_INSTANCE.new(data) }
        else
          result = [self.class::RESULT_INSTANCE.new(result)]
        end

        # If response code is 2XX and data is a String we will have an error here
        # but it's TBD if this is ever the case
        Response.new(headers, result, data["meta"])
      end
    end
  end
end
