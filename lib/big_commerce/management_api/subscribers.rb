# frozen_string_literal: true

require "big_commerce/management_api/endpoint"

module BigCommerce
  module ManagementAPI
    class Subscribers < Endpoint
      PATH = "customers/subscribers"
      RESULT_INSTANCE = Subscriber

      def create(attributes)
        result = POST(PATH, attributes)
        unwrap(result)
      end

      def delete(options)
        DELETE(
          PATH,
          with_in_param(
            options,
            :date_created,
            :date_modified,
            :email,
            :first_name,
            :id,
            :last_name,
            :order_id,
            :source
          )
        )
      end

      ##
      #
      # Given an ID find a single Subscriber. Given a Hash find Subscribers by the provided criteria.
      #
      def get(options_or_id)
        query = options_or_id

        if query.is_a?(Hash)
          query = with_in_param(
            query,
            :date_created,
            :date_modified,
            :email,
            :first_name,
            :id,
            :last_name,
            :order_id,
            :source
          )
        end

        GET(PATH, query)
      end

      def update(attributes)
        attributes = attributes.to_h

        id = attributes.delete(:id)
        if id.nil?
          raise ArgumentError, "Cannot update subscriber: given subscriber has no id"
        end

        result = UPDATE("#{PATH}/#{id}", attributes)
        unwrap(result)
      end
    end
  end
end
