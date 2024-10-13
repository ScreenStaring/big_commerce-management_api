# BigCommerce::ManagementAPI

v3 API client for [BigCommerce's REST Management API](https://developer.bigcommerce.com/docs/rest-management)

**Incomplete! v3 has many endpoints and this only provides what we need at ScreenStaring** which currently
is 99% `customers` stuff but adding new endpoints should be trivial. See [Adding New Endpoints](#adding-new-endpoints).

## Installation

Add this line to your application's `Gemfile`:

```ruby
gem "big_commerce-management_api"
```

And then execute:

    bundle install

Or install it yourself as:

    gem install big_commerce-management_api

## Usage

```rb
require "big_commerce/management_api"

bc = BigCommerce::ManagementAPI.new(store_hash, auth_token)
customers = bc.customers.get(:include => "addresses")
customers = bc.customers.get(:include => "addresses", :id => [1,2,3])

p customers.meta.request_id
p customers.meta.pagination.total

customers.each do |customer|
  p customer.first_name
  p customer.addresses[0].address_type
  # ...
end

attribute = BigCommerce::ManagementAPI::Attribute.new(
  :name => "Daily screen-staring count",
  :type => "number"
)

attribute = bc.customers.attributes.create(attribute)
p attribute.id
```

## Adding New Endpoints

1. Add JSON response body to `lib/big_commerce/management/classes.json`
1. Create or update `lib/big_commerce/management/THE_RESOURCE.rb`. See `customers.rb` for an example
1. For new classes
  - If the response JSON's top-level property is not `"data"` define `RESULT_KEY` with the name of the top-level property
  - Define `PATH` for the resource's path **after** the `v3` portion of the URL
  - Define `RESULT_INSTANCE` for the given class to use on response data pointed to by `RESULT_KEY`
1. If the method's return value should not be an `Array` call `unwrap(result)` before returning

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

---

Made by [ScreenStaring](http://screenstaring.com)
