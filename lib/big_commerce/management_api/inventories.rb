# frozen_string_literal: true

require "big_commerce/management_api/endpoint"

module BigCommerce
  module ManagementAPI
    class Inventories
      class Items < Endpoint
        PATH = "inventory/items"
        RESULT_INSTANCE = Inventory

        def get(options = {})
          GET(
            PATH,
            with_in_param(
              options,
              :location_code,
              :location_id,
              :product_id,
              :sku,
              :variant_id
            )
          )
        end
      end

      attr_reader :items

      def initialize(*argz)
        @items = Items.new(*argz)
      end
    end
  end
end
