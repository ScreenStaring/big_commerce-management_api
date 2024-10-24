RSpec.describe BigCommerce::ManagementAPI::AttributeValue, :vcr do
  describe "#create" do
    before do
      @created = []
      @attribute = client.customers.attributes.create(
        :name => "test.attribute_values.upsert",
        :type => "string"
      ).first

      @customer = client.customers.create(
        :email => "test.attributevalues.create@example.com",
        :first_name => "Test",
        :last_name => "User"
      ).first

      @created << @customer.id
    end

    after do
      client.customers.attributes.delete(@attribute.id) if @attribute
      client.customers.delete(*@created) if @created.any?
    end

    describe "#upsert" do
      describe "creating a single attribute value" do
        it "returns the new attribute value" do
          # Can check if created vs updated?
          result = client.customers.attribute_values.upsert(
            :attribute_id => @attribute.id,
            :value => "some value",
            :customer_id => @customer.id
          )

          expect(result.count).to eq 1

          value = result.first
          expect(value).to be_a(BigCommerce::ManagementAPI::AttributeValue)
          expect(value).to have_attributes(
                             :id => match(Numeric),
                             :attribute_value => "some value",
                             :attribute_id => @attribute.id,
                             :customer_id => @customer.id,
                             :date_created => match(Time),
                             :date_modified => match(Time)
                           )
        end
      end
    end
  end
end
