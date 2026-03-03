# frozen_string_literal: true

require "class2"
require "json"
require "bigdecimal"

# This results in certain properties in the JSON samples/definitions to be parsed as
# Time which class2 will see and convert the attribute values to Time
require "json/add/time"

classes = File.read(File.join(__dir__, "classes.json"))
class2 "BigCommerce::ManagementAPI", JSON.parse(classes, :create_additions => true) do
  def meta
    @meta
  end

  def meta=(meta)
    @meta = meta
  end

  def headers
    @headers
  end

  def headers=(headers)
    @headers = headers
  end
end

class BigCommerce::ManagementAPI::Product
  DECIMAL_PROPERTIES = %i[price cost_price retail_price sale_price map_price calculated_price fixed_cost_shipping_price].freeze

  # class2 giveth and class2 takith away
  alias_method :initialize_without_decimals, :initialize

  def initialize(*args)
    initialize_without_decimals(*args)

    DECIMAL_PROPERTIES.each do |prop|
      value = instance_variable_get("@#{prop}")
      instance_variable_set("@#{prop}", BigDecimal(value.to_s)) if value
    end
  end
end

require "big_commerce/management_api/customers"
require "big_commerce/management_api/inventories"
require "big_commerce/management_api/products"
require "big_commerce/management_api/segments"
require "big_commerce/management_api/subscribers"
