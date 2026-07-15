require "rails_helper"

RSpec.describe Catalog::Errors do
  it "defines a shared base error for catalog services" do
    expect(described_class::Error.superclass).to eq(StandardError)
  end

  it "defines reusable service errors under the same hierarchy" do
    expect(described_class::ProductNotFound).to be < described_class::Error
    expect(described_class::VariantNotFound).to be < described_class::Error
    expect(described_class::InvalidProduct).to be < described_class::Error
    expect(described_class::InvalidVariant).to be < described_class::Error
    expect(described_class::InvalidSku).to be < described_class::Error
    expect(described_class::DuplicateSku).to be < described_class::Error
    expect(described_class::InvalidPrice).to be < described_class::Error
    expect(described_class::InvalidDimensions).to be < described_class::Error
    expect(described_class::InvalidProductState).to be < described_class::Error
    expect(described_class::ProductNotPublishable).to be < described_class::Error
    expect(described_class::MissingDependency).to be < described_class::Error
  end
end
