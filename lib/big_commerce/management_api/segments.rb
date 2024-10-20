# frozen_string_literal: true

require "big_commerce/management_api/endpoint"

module BigCommerce
  module ManagementAPI
    class Segments < Endpoint
      PATH = "segments"
      RESULT_INSTANCE = Segment

      def create(*segments)
        segments.flatten!

        POST(PATH, segments.map(&:to_h))
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
            :id
          )
        )
      end

      def update(*segments)
        segments.flatten!

        PUT(PATH, segments.map(&:to_h))
      end
    end
  end
end
