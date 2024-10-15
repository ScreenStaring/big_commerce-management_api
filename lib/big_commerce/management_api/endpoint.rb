# frozen_string_literal: true

require "json"
require "net/http"

module BigCommerce
  module ManagementAPI
    Error = Class.new(StandardError)

    module ResponseHeaders # :nodoc:
      def request_id
        headers["x-request-id"]
      end

      %w[x-rate-limit-requests-left
         x-rate-limit-time-reset-ms
         x-rate-limit-requests-quota
         x-rate-limit-time-window-ms].each do |header|

        method = header.delete_prefix("x-")
        method.tr!("-", "_")

        define_method(method) { headers[header] }
      end
    end

    class ResponseError < Error
      include ResponseHeaders

      def initialize(data, headers)
        @headers = headers
        @data = data

        super error_message(data)
      end

      private

      attr_reader :headers

      def error_message(data)
        return data unless data.is_a?(Hash)

        if data["errors"] && data["errors"].any?
          message = data["title"].chomp(".")
          message << ": " << data["errors"].map { |property, message| "#{property}: #{message}" }.join(", ")
        else
          message = sprintf("%s (%s)", data["title"], data["status"])
        end
      end
    end

    class Endpoint # :nodoc:
      HOST = "api.bigcommerce.com"
      PORT = 443

      USER_AGENT = "BigCommerce Management API Client v#{BigCommerce::ManagementAPI::VERSION} (Ruby v#{RUBY_VERSION})"

      CONTENT_TYPE = "Content-Type"
      CONTENT_TYPE_JSON = "application/json"

      RESULT_KEY = "data"

      class Meta
        include ResponseHeaders

        attr_reader :pagination

        def initialize(headers, pagination = nil)
          @headers = headers
          @pagination = pagination
        end

        private

        attr_reader :headers
      end

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

        attr_reader :meta

        def initialize(result, headers, meta)
          @result = result
          @meta = Meta.new(headers, Pagination.new(meta["pagination"]))
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
        request(Net::HTTP::Delete.new(endpoint(path)), data)
      end

      def GET(path, data = {})
        path = endpoint(path)
        path << query_string(data) if data && data.any?
        request(Net::HTTP::Get.new(path))
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
        record
      end

      def with_in_param(options, *param_names)
        options = options.dup
        options.keys.each do |name|
          # Remove optional ":in" portion from "id:in" which may or may not be a Symbol
          name = name.to_s.split(":")[0].to_sym
          next unless param_names.include?(name)

          values = Array(options.delete(name))

          in_name = "#{name}:in"
          values.concat(Array(options.delete(in_name)))

          next unless values.any?

          options[in_name] = values.join(",")
        end

        options
      end

      private

      def query_string(params)
        params = params.dup

        params.keys.each do |name|
          params[name] = params[name].join(",") if params[name].is_a?(Array)
        end

        # TODO: do they want form or URL encoding?
        sprintf("?%s", URI.encode_www_form(params))
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

      def big_commerce_headers(response)
        headers = {}

        response.to_hash.each do |name, value|
          # Could include other x headers but the ResponseHeaders module will filter
          next unless name.start_with?("x-")

          # Net::HTTP returns them as an Array
          headers[name] = value[0]
        end

        headers
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

        request.start do |http|
          res = http.request(req)
          # TODO: data can be HTML string! Don't want this in the error!
          data = res.body && res[CONTENT_TYPE] == CONTENT_TYPE_JSON ? parse_json(res.body) : res.body
          # pp data
          headers = big_commerce_headers(res)

          raise ResponseError.new(data, headers) if res.code[0] != "2"

          result = data[self.class::RESULT_KEY]
          if result.is_a?(Array)
            result.map! { |data| self.class::RESULT_INSTANCE.new(data) }
          else
            result = [self.class::RESULT_INSTANCE.new(result)]
          end

          # If response code is 2XX and data is a String we will have an error here
          # but it's TBD if this is ever the case
          Response.new(result, headers, data["meta"])
        end
      end
    end
  end
end
