# frozen_string_literal: true

require "big_commerce/management_api/endpoint"

module BigCommerce
  module ManagementAPI
    class Products < Endpoint
      PATH = "catalog/products"
      RESULT_INSTANCE = Product

      def get(id, options = {})
        result = GET("#{PATH}/#{id}", options)
        unwrap(result)
      end

      def update(attributes)
        attributes = attributes.to_h

        id = attributes.delete(:id)
        if id.nil?
          raise ArgumentError, "Cannot update product: given product has no id"
        end

        result = PUT("#{PATH}/#{id}", attributes)
        unwrap(result)
      end
    end
  end
end
