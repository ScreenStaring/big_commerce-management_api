RSpec.describe BigCommerce::ManagementAPI::Attribute, :vcr do
  describe "#create" do
    before { @created = [] }
    after { client.customers.delete(*@created) if @created.any? }

    describe "#create" do
      describe "creating a single attribute" do
        it "returns the new attribute" do
          result = client.customers.attributes.create(
            :name => "test.attribute.create",
            :type => "string"
          )

          expect(result.count).to eq 1

          attribute = result.first
          @created << attribute.id

          expect(attribute).to be_a(BigCommerce::ManagementAPI::Attribute)
          expect(attribute).to have_attributes(
                                 :id => match(Numeric),
                                 :name => "test.attribute.create",
                                 :type => "string",
                                 :date_created => match(Time),
                                 :date_modified => match(Time)
                               )
        end
      end
    end
  end
end
