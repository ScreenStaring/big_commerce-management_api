require "bundler/setup"
require "vcr"
require "dotenv/load"
require "big_commerce/management_api"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before do
    def client
      @client ||= BigCommerce::ManagementAPI.new(
        ENV.fetch("BC_STORE_HASH"),
        ENV.fetch("BC_ACCESS_TOKEN"),
      )
    end
  end
end

VCR.configure do |c|
  c.cassette_library_dir = "spec/cassettes"
  c.hook_into :webmock
  c.configure_rspec_metadata!
  c.filter_sensitive_data("<X-Auth-Token>") { ENV.fetch("BC_ACCESS_TOKEN") }
  c.filter_sensitive_data("<STORE_HASH>") { ENV.fetch("BC_STORE_HASH") }
end
