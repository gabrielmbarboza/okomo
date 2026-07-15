require "rails_helper"

RSpec.describe Catalog::Services::PublishProduct do
  class PublishProductInMemoryProductRepository
    attr_reader :saved_products

    def initialize(products: [])
      @products = products
      @saved_products = []
    end

    def find_by_id(id)
      @products.find { |product| product.id == id }
    end

    def save(product)
      @saved_products << product
      product
    end
  end

  class PublishProductInMemoryVariantRepository
    def initialize(variants_by_product: {})
      @variants_by_product = variants_by_product
    end

    def find_by_product_id(product_id)
      Array(@variants_by_product[product_id])
    end
  end

  class PublishProductFakeEventPublisher
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
  let(:seller_profile_id) { SecureRandom.uuid }
  let(:product) do
    Catalog::Entities::Product.new(seller_profile_id: seller_profile_id, name: "Cesto", description: "Feito à mão")
  end
  let(:sellable_variant) { Catalog::Entities::Variant.new(product_id: product.id, name: "Cesto", sku: "SKU-1", price: 10) }
  let(:product_repository) { PublishProductInMemoryProductRepository.new(products: [ product ]) }
  let(:variant_repository) do
    PublishProductInMemoryVariantRepository.new(variants_by_product: { product.id => [ sellable_variant ] })
  end
  let(:event_publisher) { PublishProductFakeEventPublisher.new }

  def call_service(product_id: product.id, repository: product_repository, variants: variant_repository)
    described_class.call(
      product_id: product_id,
      product_repository: repository,
      variant_repository: variants,
      event_publisher: event_publisher,
      clock: -> { now }
    )
  end

  it "publishes a draft product with at least one sellable variant" do
    result = call_service

    expect(result).to be_success
    expect(result.product.published?).to be(true)
    expect(result.product.updated_at).to eq(now)
    expect(product_repository.saved_products).to eq([ result.product ])
    expect(event_publisher.events).to contain_exactly(an_instance_of(Catalog::Events::ProductPublished))
    expect(result.events).to eq(event_publisher.events)
  end

  it "publishes ProductPublished with the expected payload" do
    result = call_service
    event = result.events.first

    expect(event.payload).to eq(
      product_id: result.product.id,
      seller_profile_id: seller_profile_id,
      published_at: now
    )
    expect(event.occurred_at).to eq(now)
  end

  it "raises ProductNotFound when the product does not exist" do
    expect {
      call_service(product_id: SecureRandom.uuid)
    }.to raise_error(described_class::ProductNotFound)
  end

  it "raises InvalidProductState when the product is not draft" do
    published_product = Catalog::Entities::Product.new(
      seller_profile_id: seller_profile_id, name: "Cesto", description: "Feito à mão", status: "published"
    )
    repository = PublishProductInMemoryProductRepository.new(products: [ published_product ])
    variants = PublishProductInMemoryVariantRepository.new(
      variants_by_product: { published_product.id => [ sellable_variant ] }
    )

    expect {
      call_service(product_id: published_product.id, repository: repository, variants: variants)
    }.to raise_error(described_class::InvalidProductState, "product must be draft to be published")
  end

  it "raises ProductNotPublishable when the product has no description" do
    product_without_description = Catalog::Entities::Product.new(seller_profile_id: seller_profile_id, name: "Cesto")
    repository = PublishProductInMemoryProductRepository.new(products: [ product_without_description ])
    variants = PublishProductInMemoryVariantRepository.new(
      variants_by_product: { product_without_description.id => [ sellable_variant ] }
    )

    expect {
      call_service(product_id: product_without_description.id, repository: repository, variants: variants)
    }.to raise_error(described_class::ProductNotPublishable, "product must have a description to be published")
  end

  it "raises ProductNotPublishable when the product has no variants" do
    empty_variant_repository = PublishProductInMemoryVariantRepository.new

    expect {
      call_service(variants: empty_variant_repository)
    }.to raise_error(described_class::ProductNotPublishable, "product must have at least one sellable variant")
  end

  it "raises ProductNotPublishable when all variants are archived" do
    archived_variant = Catalog::Entities::Variant.new(
      product_id: product.id, name: "Cesto", sku: "SKU-2", price: 10, status: "archived"
    )
    archived_only_repository = PublishProductInMemoryVariantRepository.new(
      variants_by_product: { product.id => [ archived_variant ] }
    )

    expect {
      call_service(variants: archived_only_repository)
    }.to raise_error(described_class::ProductNotPublishable, "product must have at least one sellable variant")
  end
end
