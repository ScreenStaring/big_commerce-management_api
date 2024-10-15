require "big_commerce/management_api/endpoint"

module BigCommerce
  module ManagementAPI
    class Subscribers < Endpoint
      PATH = "customers/subscribers"
      RESULT_INSTANCE = Subscriber

      def get(options = {})
        GET(
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

      def create(attributes)
        result = POST(PATH, attributes.to_h)
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
    end
  end
end
