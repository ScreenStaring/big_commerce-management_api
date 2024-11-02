# BigCommerce::ManagementAPI

![CI Status](https://github.com/ScreenStaring/big_commerce-management_api/actions/workflows/ci.yml/badge.svg)

v3 API client for [BigCommerce's REST Management API](https://developer.bigcommerce.com/docs/rest-management)

**Incomplete! v3 has many endpoints and this only provides what we need at ScreenStaring** which currently
is mostly customers and subscribers stuff but adding new endpoints should be trivial. See [Adding New Endpoints](#adding-new-endpoints).

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
customers = bc.customers.get
customers = bc.customers.get(:id => [1,2,3], :include => %w[addresses formfields])

p customers.meta.pagination.total
p customers.headers.request_id
p customers.headers["some-header"]

# customers is Enumerable
customers.each do |customer|
  p customer.first_name
  p customer.addresses[0].address_type
  # ...
end

begin
  customers = bc.customers.get(:page => 2, :limit => 99) # limit defaults to 250
rescue BigCommerce::ManagementAPI::ResponseError => e
  p e.message
  p e.headers.rate_limit_requests_left
end

attribute = bc.customers.attributes.create(
  :name => "Daily screen-staring count",
  :type => "number"
)
p attribute.id
p attribute.meta.total # 1
```

## Adding New Endpoints

1. Add JSON response body to `lib/big_commerce/management/classes.json`
1. Create or update `lib/big_commerce/management/THE_RESOURCE.rb`. See `customers.rb` for an example
1. For new classes
   - If the response JSON's top-level property is not `"data"` define `RESULT_KEY` with the name of the top-level property
   - Define `RESULT_INSTANCE` and set it to the class to use on response data pointed to by `RESULT_KEY`
   - Call the appropriate HTTP verb method passing the endpoint's path (the portion **after** the API's `v3` URL) and parameters
1. If the method's return value should not be an `Array` call `unwrap(result)` before returning

## Testing

Tests use [VCR](https://github.com/vcr/vcr). If you need to re-record cassettes or create new ones a BigCommerce
account is with API access is required. See `.env.test.example`.

To re-record certain tests you must import fixture data into your store. See `etc/customers.csv`. These records can be deleted once
the VCR cassettes are recorded and you are done with development. The IDs they create are assumed by the tests which may present
a problem. Open an issue if so.

Any records that are created by the tests are deleted. Well, a delete is attempted in an `after` block, if something goes wrong with the test
the record(s) may remain in your store.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

---

Made by [ScreenStaring](http://screenstaring.com)
