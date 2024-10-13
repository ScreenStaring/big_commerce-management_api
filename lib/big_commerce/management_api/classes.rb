# frozen_string_literal: true

require "class2"
require "json"

classes = File.read(File.join(__dir__, "classes.json"))
class2 "BigCommerce::ManagementAPI", JSON.parse(classes) do
  def meta
    @meta
  end

  def meta=(meta)
    @meta = meta
  end
end

require "big_commerce/management_api/customers"
require "big_commerce/management_api/inventories"
