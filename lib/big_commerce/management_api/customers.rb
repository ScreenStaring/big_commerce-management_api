# frozen_string_literal: true

require "big_commerce/management_api/endpoint"

module BigCommerce
  module ManagementAPI
    class Customers < Endpoint
      class Addresses < Endpoint
        PATH = "customers/addresses"
        RESULT_INSTANCE = Address

        def create(*attributes)
          attributes.flatten!

          POST(PATH, attributes.map(&:to_h))
        end

        def delete(*ids)
          ids.flatten!

          DELETE(
            PATH,
            with_in_param({:id => ids}, :id)
          )
        end

        def get(options = {})
          GET(
            PATH,
            with_in_param(
              options,
              :company,
              :customer_id,
              :id,
              :name
            )
          )
        end
      end

      class Attributes < Endpoint
        PATH = "customers/attributes"
        RESULT_INSTANCE = Attribute

        def get(options = {})
          GET(PATH, options)
        end

        def create(*attributes)
          attributes.flatten!

          POST(PATH, attributes.map(&:to_h))
        end

        def delete(*ids)
          ids.flatten!

          DELETE(
            PATH,
            with_in_param({:id => ids}, :id)
          )
        end
      end

      class AttributeValues < Endpoint
        PATH = "customers/attribute-values"
        RESULT_INSTANCE = AttributeValue

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
          attributes.flatten!

          PUT(PATH, attributes)
        end
      end

      class Metafields < Endpoint
        PATH = "customers/%d/metafields"
        RESULT_INSTANCE = Metafield

        def get(customer_id, options = {})
          GET(path(customer_id), options)
        end

        def create(metafield)
          metafield = metafield.to_h
          id = metafield.delete(:resource_id)

          if id.nil?
            raise ArgumentError, "Cannot create customer metafield: given metafield record has no resource_id"
          end

          POST(path(id), metafield)
        end

        def update(metafield)
          metafield = metafield.to_h

          resource = metafield.delete(:resource_id)
          if resource.nil?
            raise ArgumentError, "Cannot update customer metafield: given metafield has no resource_id"
          end

          id = metafield.delete(:id)
          if id.nil?
            raise ArgumentError, "Cannot update customer metafield: given metafield has no id"
          end

          result = PUT(path(resource_id, id), metafield)
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

      attr_reader :addresses,
                  :attributes,
                  :attribute_values,
                  :metafields

      def initialize(*argz)
        super(*argz)

        @addresses = Addresses.new(*argz)
        @attributes = Attributes.new(*argz)
        @attribute_values = AttributeValues.new(*argz)
        @metafields = Metafields.new(*argz)
      end

      def create(*customers)
        customers.flatten!

        POST(PATH, customers.map(&:to_h))
      end

      def delete(*ids)
        ids.flatten!

        DELETE(
          PATH,
          with_in_param({:id => ids}, :id)
        )
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
        customers.flatten!

        PUT(PATH, customers.map(&:to_h))
      end
    end
  end
end
