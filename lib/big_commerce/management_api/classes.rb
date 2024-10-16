# frozen_string_literal: true

require "class2"
require "json"

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
end

require "big_commerce/management_api/customers"
require "big_commerce/management_api/inventories"
require "big_commerce/management_api/subscribers"
