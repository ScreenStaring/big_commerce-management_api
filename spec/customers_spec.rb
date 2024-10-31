RSpec.describe BigCommerce::ManagementAPI::Customers, :vcr do
  before { @created = [] }

  after do
    client.customers.delete(*@created) if @created.any?
  end

  describe "#customers" do
    describe "#create" do
      describe "creating a single customer" do
        it "returns the new customer" do
          result = client.customers.create(
            :email => "test.customers.get@example.com",
            :first_name => "Bill",
            :last_name => "Bellamy",
            :company => "Thangz Inc.",
            :phone => "510-555-1212",
            :notes => "Duly noted!",
            # :tax_exempt_category => nil,
            # :customer_group_id => 0
          )

          expect(result.count).to eq 1

          customer = result.first
          @created << customer.id

          expect(customer).to be_a(BigCommerce::ManagementAPI::Customer)
          expect(customer).to have_attributes(
                                :email => "test.customers.get@example.com",
                                :first_name => "Bill",
                                :last_name => "Bellamy",
                                :company => "Thangz Inc.",
                                :phone => "510-555-1212",
                                :notes => "Duly noted!",
                                :tax_exempt_category => "",
                                # BC default
                                :customer_group_id => 0
                              )
        end

        it "raises an error when the customer is invalid" do
          expect {
            client.customers.create(
              :email => "not-an-email",
              :first_name => "Jay",
              :last_name => "Cat"
            )
          }.to raise_error(BigCommerce::ManagementAPI::ResponseError, /invalid email/)
        end
      end
    end

    describe "#get" do
      it "returns a list of customers" do
        result = client.customers.get
        expect(result.count).to eq 5

        customers = result.sort_by(&:email)
        expect(customers[0]).to be_a BigCommerce::ManagementAPI::Customer
        expect(customers[0]).to have_attributes(
                                  :first_name => "John",
                                  :last_name => "Doe",
                                  :email => "user1@example.com"
                                )

        expect(customers[1]).to be_a BigCommerce::ManagementAPI::Customer
        expect(customers[1]).to have_attributes(
                                  :first_name => "Bob",
                                  :last_name => "John",
                                  :email => "user2@example.com"
                                )
      end

      describe ":date_created:min" do
        it "returns customers created after the given date" do
          # This is the time the VCR cassette was recorded
          # If test is re-recorded switch use Time.now first. Other ways to do this?
          # Can't freeze time on API server!

          # after = Time.now
          after = Time.parse("2024-10-30T22:30:38-0400")
          result = client.customers.create(
            {
              :email => "test.customers.created.at.min1@example.com",
              :first_name => "John",
              :last_name => "Doe"
            },
            {
              :email => "test.customers.created.at.min2@example.com",
              :first_name => "Jane",
              :last_name => "Doe"
            }
          )

          @created.concat(result.map(&:id))

          result = client.customers.get("date_created:min" => after)
          expect(result.count).to eq 2

          customers = result.sort_by(&:email)
          expect(customers[0]).to be_a(BigCommerce::ManagementAPI::Customer)
          expect(customers[0].email).to eq "test.customers.created.at.min1@example.com"

          expect(customers[1]).to be_a(BigCommerce::ManagementAPI::Customer)
          expect(customers[1].email).to eq "test.customers.created.at.min2@example.com"
        end
      end

      describe ":id" do
        context "given a single ID" do
          it "returns the customer with the given ID" do
            result = client.customers.get(:id => 1)
            expect(result.count).to eq 1

            customer = result.first
            expect(customer).to be_a(BigCommerce::ManagementAPI::Customer)
            expect(customer).to have_attributes(
                                  :id => 1,
                                  :first_name => "John",
                                  :last_name => "Doe"
                                )
          end

          it "returns an empty result when customer with the given ID does not exist" do
            result = client.customers.get(:id => 999999)
            expect(result.count).to eq 0
          end
        end

        context "given an Array containing multiple IDs" do
          it "returns the customers with the given IDs" do
            result = client.customers.get(:id => [1, 5])
            expect(result.count).to eq 2

            customers = result.to_a
            expect(customers[0]).to have_attributes(
                                      :id => 1,
                                      :first_name => "John",
                                      :last_name => "Doe"
                                    )
            expect(customers[1]).to have_attributes(
                                      :id => 5,
                                      :first_name => "Caio",
                                      :last_name => "Oliver"
                                    )
          end
        end
      end

      describe ":include" do
        context "given a single relation's name" do
          it "returns customers including the relation" do
            result = client.customers.get(:include => "addresses")
            expect(result.count).to eq 5

            customers = result.sort_by(&:email)
            expect(customers[0]).to be_a(BigCommerce::ManagementAPI::Customer)

            # Just check a few to ensure we're getting what we expect via include
            addresses = customers[0].addresses
            expect(addresses.size).to eq 1
            expect(addresses[0]).to be_a(BigCommerce::ManagementAPI::Address)
            expect(addresses[0]).to have_attributes(
                                      "id"=> be_a(Integer),
                                      "address1" => "59 West 46th Street",
                                      "address2" => "",
                                      "address_type" => "residential",
                                      "city" => "New York",
                                      "company" => "Fofiha",
                                      "country" => "United States",
                                      "country_code" => "US",
                                      "customer_id" => be_a(Integer),
                                      "first_name" => "",
                                      "last_name" => "",
                                      "phone" => "555-555-1212",
                                      "postal_code" => "10005",
                                      "state_or_province" => "New York"
                                    )

            addresses = customers[1].addresses
            expect(addresses.size).to eq 1
            expect(addresses[0]).to be_a(BigCommerce::ManagementAPI::Address)
            expect(addresses[0]).to have_attributes(
                                      "id"=> be_a(Integer),
                                      "address1" => "123 55th St.",
                                      "address2" => "#1",
                                      "address_type" => "residential",
                                      "city" => "New York",
                                      "company" => "",
                                      "country" => "United States",
                                      "country_code" => "US",
                                      "customer_id" => be_a(Integer),
                                      "first_name" => "",
                                      "last_name" => "",
                                      "phone" => "212-555-1212",
                                      "postal_code" => "10038",
                                      "state_or_province" => "New York"
                                    )

          end
        end

        context "given an Array containing multiple relations" do
          it "returns customers including both relations" do
            result = client.customers.get(:include => %w[addresses storecredit])
            expect(result.count).to eq 5

            # Just check a few to ensure we're getting what we expect via include
            customers = result.sort_by(&:email)
            expect(customers[0]).to be_a(BigCommerce::ManagementAPI::Customer)
            expect(customers[0].email).to eq "user1@example.com"

            addresses = customers[0].addresses
            expect(addresses.size).to eq 1
            expect(addresses[0]).to be_a(BigCommerce::ManagementAPI::Address)
            expect(addresses[0].address1).to eq "59 West 46th Street"

            credits = customers[0].store_credit_amounts
            expect(credits.size).to eq 1
            expect(credits[0]).to be_a(BigCommerce::ManagementAPI::StoreCreditAmount)
            expect(credits[0].amount).to eq 59.99

            expect(customers[1]).to be_a(BigCommerce::ManagementAPI::Customer)
            expect(customers[1].email).to eq "user2@example.com"

            addresses = customers[1].addresses
            expect(addresses.size).to eq 1
            expect(addresses[0]).to be_a(BigCommerce::ManagementAPI::Address)
            expect(addresses[0].address1).to eq "123 55th St."

            credits = customers[1].store_credit_amounts
            expect(credits.size).to eq 1
            expect(credits[0]).to be_a(BigCommerce::ManagementAPI::StoreCreditAmount)
            expect(credits[0].amount).to eq 0.0

            expect(customers[2]).to be_a(BigCommerce::ManagementAPI::Customer)
            expect(customers[2].email).to eq "user3@example.com"

            addresses = customers[2].addresses
            expect(addresses.size).to eq 1
            expect(addresses[0]).to be_a(BigCommerce::ManagementAPI::Address)
            expect(addresses[0].address1).to eq "21 W. 21st St."

            credits = customers[2].store_credit_amounts
            expect(credits.size).to eq 1
            expect(credits[0]).to be_a(BigCommerce::ManagementAPI::StoreCreditAmount)
            expect(credits[0].amount).to eq 101.0
          end
        end
      end

      describe "pagination" do
        before { @result = client.customers.get(:page => 2, :limit => 2) }

        it "returns the customers at the specified :page and :limit" do
          expect(@result.count).to eq 2

          emails = @result.map(&:email)
          expect(emails).to contain_exactly("user3@example.com", "user4@example.com")
        end

        it "makes the pagination values available on the result" do
          pages = @result.meta.pagination
          expect(pages).to have_attributes(
                             :count => 2,
                             :current_page => 2,
                             :per_page => 2,
                             :total => 5,
                             :total_pages => 3
                           )
        end
      end
    end
  end
end
