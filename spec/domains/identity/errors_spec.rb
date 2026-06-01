require "rails_helper"

RSpec.describe Identity::Errors do
  it "defines a shared base error for identity services" do
    expect(described_class::Error.superclass).to eq(StandardError)
  end

  it "defines reusable service errors under the same hierarchy" do
    expect(described_class::UserNotFound).to be < described_class::Error
    expect(described_class::SellerProfileNotFound).to be < described_class::Error
    expect(described_class::PermissionDenied).to be < described_class::Error
    expect(described_class::MissingDependency).to be < described_class::Error
  end
end
