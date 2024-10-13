# frozen_string_literal: true

require "big_commerce/management_api/classes"

module BigCommerce
  module ManagementAPI
    def self.new(*argz)
      Client.new(*argz)
    end

    class Client
      attr_reader :customers, :inventories

      def initialize(*argz)
        @customers = ManagementAPI::Customers.new(*argz)
        @inventories = ManagementAPI::Inventories.new(*argz)
      end
    end
  end
end
