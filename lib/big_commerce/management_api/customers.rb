# frozen_string_literal: true

require "big_commerce/management_api/endpoint"

module BigCommerce
  module ManagementAPI
    class Customers < Endpoint
      class Attributes < Endpoint
        PATH = "customers/attributes"
        RESULT_INSTANCE = Attribute

        def get(options = {})
          GET(PATH, options)
        end

        def create(*attributes)
          POST(PATH, attributes.map(&:to_h))
        end
      end

      class AttributeValues < Endpoint
        PATH = "customers/attribute-values"
        RESULT_INSTANCE = AttributeValues

        def get(options = {})
          GET(
            PATH,
            with_in_param(
              options,
              :attribute_id,
              :customer_id
            )
          )
        end

        def upsert(*attributes)
          PUT(PATH, attributes.map(&:to_h))
        end
      end

      class Metafields < Endpoint
        PATH = "customers/%d/metafields"
        RESULT_INSTANCE = Metafield

        def get(customer_id, options = {})
          GET(path(customer_id), options)
        end

        def create(metafield)
          if metafield.resource_id.nil?
            raise ArgumentError, "Cannot create customer metafield: given metafield record has no resource id"
          end

          POST(path(metafield.resource_id), metafield.to_h)
        end

        def update(metafield)
          if metafield.id.nil?
            raise ArgumentError, "Cannot update customer metafield: given metafield record has no ID"
          end

          result = PUT(path(metafield.resource_id, metafield.id), metafield.to_h)
          unwrap(result)
        end

        private

        def path(customer_id, *rest)
          path = sprintf(PATH, customer_id)
          return path if rest.empty?

          path << "/" << rest.join("/")
        end
      end

      PATH = "customers"
      RESULT_INSTANCE = Customer

      attr_reader :attributes,
                  :attribute_values,
                  :metafields

      def initialize(*argz)
        super *argz
        @attributes = Attributes.new(*argz)
        @attribute_values = AttributeValues.new(*argz)
        @metafields = Metafields.new(*argz)
      end

      def get(options = {})
        GET(
          PATH,
          with_in_param(
            options,
            :company,
            :customer_group_id,
            :email,
            :id,
            :name,
            :registration_ip_address
          )
        )
      end

      def update(*customers)
        PUT(PATH, customers.map(&:to_h))
      end
    end
  end
end
