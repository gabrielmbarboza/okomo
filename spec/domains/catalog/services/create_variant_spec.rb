require "rails_helper"

RSpec.describe Catalog::Services::CreateVariant do
  class CreateVariantInMemoryProductRepository
    def initialize(products: [])
      @products = products
    end

    def find_by_id(id)
      @products.find { |product| product.id == id }
    end
  end

  class CreateVariantInMemoryVariantRepository
    attr_reader :variants

    def initialize(existing_skus_by_product: {})
      @existing_skus_by_product = existing_skus_by_product
      @variants = []
    end

    def sku_exists_for_product?(product_id, sku)
      Array(@existing_skus_by_product[product_id]).include?(sku) ||
        @variants.any? { |variant| variant.product_id == product_id && variant.sku == sku }
    end

    def save(variant)
      @variants << variant
      variant
    end
  end

  class CreateVariantFakeEventPublisher
    attr_reader :events

    def initialize
      @events = []
    end

    def publish(event)
      @events << event
      true
    end
  end

  let(:now) { Time.zone.parse("2026-07-14 10:00:00") }
  let(:product) { Catalog::Entities::Product.new(seller_profile_id: SecureRandom.uuid, name: "Cesto") }
  let(:product_repository) { CreateVariantInMemoryProductRepository.new(products: [ product ]) }
  let(:variant_repository) { CreateVariantInMemoryVariantRepository.new }
  let(:event_publisher) { CreateVariantFakeEventPublisher.new }

  def call_service(
    product_id: product.id, name: "Cesto de Bambu", sku: "CESTO-BAMBU", price: 49.9,
    weight_grams: nil, height_cm: nil, width_cm: nil, length_cm: nil
  )
    described_class.call(
      product_id: product_id,
      name: name,
      sku: sku,
      price: price,
      weight_grams: weight_grams,
      height_cm: height_cm,
      width_cm: width_cm,
      length_cm: length_cm,
      product_repository: product_repository,
      variant_repository: variant_repository,
      event_publisher: event_publisher,
      clock: -> { now }
    )
  end

  it "creates a draft variant, persists it and publishes VariantCreated" do
    result = call_service
    variant = result.variant

    expect(result).to be_success
    expect(variant).to be_a(Catalog::Entities::Variant)
    expect(variant.product_id).to eq(product.id)
    expect(variant.sku).to eq("CESTO-BAMBU")
    expect(variant.price).to eq(49.9)
    expect(variant.status).to eq("draft")
    expect(variant_repository.variants).to eq([ variant ])
    expect(event_publisher.events).to contain_exactly(an_instance_of(Catalog::Events::VariantCreated))
    expect(result.events).to eq(event_publisher.events)
  end

  it "publishes VariantCreated with the expected payload" do
    result = call_service
    event = result.events.first

    expect(event.payload).to eq(
      variant_id: result.variant.id,
      product_id: product.id,
      sku: "CESTO-BAMBU",
      created_at: now
    )
    expect(event.occurred_at).to eq(now)
  end

  it "raises ProductNotFound when the product does not exist" do
    expect {
      call_service(product_id: SecureRandom.uuid)
    }.to raise_error(described_class::ProductNotFound)

    expect(variant_repository.variants).to be_empty
  end

  it "raises InvalidVariant for a blank name" do
    expect {
      call_service(name: "")
    }.to raise_error(described_class::InvalidVariant, "name cannot be nil or empty")
  end

  it "raises InvalidSku for a blank sku" do
    expect {
      call_service(sku: "")
    }.to raise_error(described_class::InvalidSku, "sku cannot be nil or empty")
  end

  it "raises InvalidPrice when price is not greater than zero" do
    expect {
      call_service(price: 0)
    }.to raise_error(described_class::InvalidPrice, "price must be greater than zero")
  end

  it "raises InvalidDimensions when a dimension is not positive" do
    expect {
      call_service(weight_grams: -1)
    }.to raise_error(described_class::InvalidDimensions, "weight_grams must be positive")
  end

  it "raises DuplicateSku when the sku already exists for the same product (BR-CAT-010)" do
    scoped_repository = CreateVariantInMemoryVariantRepository.new(
      existing_skus_by_product: { product.id => [ "CESTO-BAMBU" ] }
    )

    expect {
      described_class.call(
        product_id: product.id, name: "Cesto de Metal", sku: "CESTO-BAMBU", price: 10,
        product_repository: product_repository, variant_repository: scoped_repository,
        event_publisher: event_publisher, clock: -> { now }
      )
    }.to raise_error(described_class::DuplicateSku, "sku already exists for this product")
  end

  it "allows the same sku to be reused across different products (BR-CAT-010 scoped uniqueness)" do
    other_product = Catalog::Entities::Product.new(seller_profile_id: SecureRandom.uuid, name: "Caneca")
    scoped_repository = CreateVariantInMemoryVariantRepository.new(
      existing_skus_by_product: { other_product.id => [ "CESTO-BAMBU" ] }
    )

    result = described_class.call(
      product_id: product.id, name: "Cesto de Metal", sku: "CESTO-BAMBU", price: 10,
      product_repository: product_repository, variant_repository: scoped_repository,
      event_publisher: event_publisher, clock: -> { now }
    )

    expect(result).to be_success
  end
end
