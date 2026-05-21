require "rails_helper"

RSpec.describe Identity::ValueObjects::PasswordResetToken do
  let(:now) { Time.zone.parse("2026-05-20 10:00:00") }

  it "represents a usable password reset token" do
    token = described_class.new(
      raw_token: "raw-token",
      token_digest: Digest::SHA256.hexdigest("raw-token"),
      expires_at: now + 2.hours,
      used_at: nil
    )

    expect(token).not_to be_expired(now: now)
    expect(token).not_to be_used
    expect(token).to be_usable(now: now)
  end

  it "is expired when expiration is reached" do
    token = described_class.new(
      raw_token: "raw-token",
      token_digest: Digest::SHA256.hexdigest("raw-token"),
      expires_at: now,
      used_at: nil
    )

    expect(token).to be_expired(now: now)
    expect(token).not_to be_usable(now: now)
  end

  it "is not usable after being used" do
    token = described_class.new(
      raw_token: "raw-token",
      token_digest: Digest::SHA256.hexdigest("raw-token"),
      expires_at: now + 2.hours,
      used_at: now - 1.minute
    )

    expect(token).to be_used
    expect(token).not_to be_usable(now: now)
  end

  it "requires token data" do
    expect {
      described_class.new(raw_token: "", token_digest: "digest", expires_at: now)
    }.to raise_error(ArgumentError, "raw_token cannot be nil or empty")

    expect {
      described_class.new(raw_token: "raw-token", token_digest: "", expires_at: now)
    }.to raise_error(ArgumentError, "token_digest cannot be nil or empty")

    expect {
      described_class.new(raw_token: "raw-token", token_digest: "digest", expires_at: nil)
    }.to raise_error(ArgumentError, "expires_at cannot be nil")
  end
end
