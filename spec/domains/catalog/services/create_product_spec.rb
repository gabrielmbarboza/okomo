require "rails_helper"

RSpec.describe Catalog::Services::CreateProduct do
  class CreateProductInMemoryProductRepository
    attr_reader :products

    def initialize
      @products = []
    end

    def save(product)
      @products << product
      product
    end
  end

  class CreateProductFakeEventPublisher
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
  let(:repository) { CreateProductInMemoryProductRepository.new }
  let(:event_publisher) { CreateProductFakeEventPublisher.new }
  let(:seller_profile_id) { SecureRandom.uuid }

  def call_service(seller_profile_id: self.seller_profile_id, name: "Cesto Artesanal", description: "Feito à mão")
    described_class.call(
      seller_profile_id: seller_profile_id,
      name: name,
      description: description,
      product_repository: repository,
      event_publisher: event_publisher,
      clock: -> { now }
    )
  end

  it "creates a draft product, persists it and publishes ProductCreated" do
    result = call_service
    product = result.product

    expect(result).to be_success
    expect(product).to be_a(Catalog::Entities::Product)
    expect(product.seller_profile_id).to eq(seller_profile_id)
    expect(product.name).to eq("Cesto Artesanal")
    expect(product.description).to eq("Feito à mão")
    expect(product.status).to eq("draft")
    expect(product.created_at).to eq(now)
    expect(repository.products).to eq([ product ])
    expect(event_publisher.events).to contain_exactly(an_instance_of(Catalog::Events::ProductCreated))
    expect(result.events).to eq(event_publisher.events)
  end

  it "publishes ProductCreated with the expected payload" do
    result = call_service
    event = result.events.first

    expect(event.payload).to eq(
      product_id: result.product.id,
      seller_profile_id: seller_profile_id,
      created_at: now
    )
    expect(event.occurred_at).to eq(now)
  end

  it "rejects a blank seller_profile_id" do
    expect {
      call_service(seller_profile_id: "")
    }.to raise_error(described_class::InvalidProduct, "seller_profile_id cannot be nil or empty")

    expect(repository.products).to be_empty
  end

  it "rejects a blank name" do
    expect {
      call_service(name: "")
    }.to raise_error(described_class::InvalidProduct, "name cannot be nil or empty")

    expect(repository.products).to be_empty
  end
end
