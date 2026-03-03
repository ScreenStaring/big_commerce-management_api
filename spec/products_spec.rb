RSpec.describe BigCommerce::ManagementAPI::Products, :vcr do
  describe "#products" do
    before { @product_id = ENV.fetch("BC_PRODUCT_ID").to_i }

    describe "#get" do
      it "returns the product with the given ID" do
        product = client.products.get(@product_id)

        expect(product).to be_a BigCommerce::ManagementAPI::Product
        expect(product.id).to eq @product_id

        expect(product.name).to be_a(String)
        expect(product.name.size).to be > 0
        expect(product.date_created).to be_a(Time)
        expect(product.date_modified).to be_a(Time)
        expect(product.primary_image).to be_a(BigCommerce::ManagementAPI::PrimaryImage)
        expect(product.primary_image.to_h.keys).to contain_exactly(:id, :product_id, :is_thumbnail, :sort_order, :description, :image_file, :date_modified)
        expect(product.to_h.keys).to include(
          :type,
          :sku,
          :description,
          :weight,
          :width,
          :depth,
          :height,
          :price,
          :cost_price,
          :retail_price,
          :sale_price,
          :map_price,
          :tax_class_id,
          :product_tax_code,
          :calculated_price,
          :categories,
          :brand_id,
          :brand_name,
          :option_set_id,
          :option_set_display,
          :inventory_level,
          :inventory_warning_level,
          :inventory_tracking,
          :reviews_rating_sum,
          :reviews_count,
          :total_sold,
          :fixed_cost_shipping_price,
          :is_free_shipping,
          :is_visible,
          :is_featured,
          :related_products,
          :warranty,
          :bin_picking_number,
          :layout_file,
          :upc,
          :mpn,
          :gtin,
          :search_keywords,
          :availability,
          :availability_description,
          :gift_wrapping_options_type,
          :gift_wrapping_options_list,
          :sort_order,
          :condition,
          :is_condition_shown,
          :order_quantity_minimum,
          :order_quantity_maximum,
          :page_title,
          :meta_keywords,
          :meta_description,
          :view_count,
          :preorder_release_date,
          :preorder_message,
          :is_preorder_only,
          :is_price_hidden,
          :price_hidden_label,
          :base_variant_id,
          :open_graph_type,
          :open_graph_title,
          :open_graph_description,
          :open_graph_use_meta_description,
          :open_graph_use_product_name,
          :open_graph_use_image,
          :date_last_imported,
          :custom_url,
          :custom_fields,
          :bulk_pricing_rules,
          :images,
          :videos
        )
      end

      it "returns response headers" do
        product = client.products.get(@product_id)
        expect(product.headers).to be_a BigCommerce::ManagementAPI::ResponseHeaders
      end

      context "with :include_fields" do
        it "returns the product with only the specified fields" do
          product = client.products.get(@product_id, :include_fields => %w[price])

          expect(product).to be_a(BigCommerce::ManagementAPI::Product)
          expect(product.name).to be_nil
        end
      end

      context "with :exclude_fields" do
        it "returns the product without the excluded fields" do
          product = client.products.get(@product_id, :exclude_fields => %w[name])

          expect(product).to be_a(BigCommerce::ManagementAPI::Product)
          expect(product.name).to be_nil
        end
      end
    end

    describe "#update" do
      it "updates the product and returns it" do
        product = client.products.get(@product_id)
        new_name = product.name.reverse << "!"
        new_price = (product.price || 0) + 1

        product = client.products.update(:id => @product_id, :name => new_name, :price => new_price)

        expect(product).to be_a(BigCommerce::ManagementAPI::Product)
        expect(product.name).to eq new_name

        product = client.products.get(@product_id)
        expect(product.name).to eq new_name
        expect(product.price).to eq new_price
      end

      it "raises an error when no id is given" do
        expect {
          client.products.update(:name => "No ID")
        }.to raise_error(ArgumentError, /no id/)
      end
    end
  end
end
