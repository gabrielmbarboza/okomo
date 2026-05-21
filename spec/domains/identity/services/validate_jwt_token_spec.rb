require "rails_helper"

RSpec.describe Identity::Services::ValidateJwtToken do
  let(:now) { Time.zone.parse("2026-05-20 14:30:00") }
  let(:secret) { "test-secret" }
  let(:user_id) { SecureRandom.uuid }
  let(:roles) { [ Identity::Entities::Role::BUYER ] }

  def generate_token(signing_secret: secret, **overrides)
    payload = {
      sub: user_id,
      roles: roles,
      iat: now.to_i,
      exp: (now + 15.minutes).to_i,
      iss: Identity::Services::GenerateJwtToken::ISSUER,
      aud: Identity::Services::GenerateJwtToken::AUDIENCE,
      jti: SecureRandom.uuid
    }.merge(overrides)

    JWT.encode(payload, signing_secret, Identity::Services::GenerateJwtToken::ALGORITHM)
  end

  it "validates a signed access token and returns normalized claims" do
    token = generate_token

    result = described_class.call(token: token, secret: secret, clock: -> { now })

    expect(result).to be_success
    expect(result.user_id).to eq(user_id)
    expect(result.roles).to eq(roles)
    expect(result.expires_at).to eq(Time.zone.at((now + 15.minutes).to_i))
    expect(result.issued_at).to eq(Time.zone.at(now.to_i))
    expect(result.token_id).to be_present
  end

  it "rejects expired tokens" do
    token = generate_token(exp: (now - 1.minute).to_i)

    expect {
      described_class.call(token: token, secret: secret, clock: -> { now })
    }.to raise_error(described_class::ExpiredToken, "token has expired")
  end

  it "rejects tokens signed with another secret" do
    token = generate_token(signing_secret: "other-secret")

    expect {
      described_class.call(token: token, secret: secret, clock: -> { now })
    }.to raise_error(described_class::InvalidToken, "token is invalid")
  end

  it "rejects tokens with invalid issuer" do
    token = generate_token(iss: "unknown")

    expect {
      described_class.call(token: token, secret: secret, clock: -> { now })
    }.to raise_error(described_class::InvalidToken, "token is invalid")
  end

  it "rejects tokens missing required claims" do
    token = generate_token(sub: nil)

    expect {
      described_class.call(token: token, secret: secret, clock: -> { now })
    }.to raise_error(described_class::InvalidClaims, "token payload is missing required claims")
  end
end
