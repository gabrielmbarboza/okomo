require "rails_helper"

RSpec.describe Identity::Services::GenerateJwtToken do
  let(:now) { Time.zone.parse("2026-05-20 14:30:00") }
  let(:user_id) { SecureRandom.uuid }
  let(:user) do
    Identity::Entities::User.new(
      id: user_id,
      name: "Jane Doe",
      email: "jane.doe@example.com",
      password_digest: "hashed-password",
      status: Identity::Entities::User::ACTIVE,
      email_confirmed_at: now - 1.day
    )
  end
  let(:secret) { "test-secret" }
  let(:roles) { [ Identity::Entities::Role::BUYER ] }

  it "generates a signed access token with authentication claims" do
    result = described_class.call(
      user: user,
      roles: roles,
      secret: secret,
      clock: -> { now }
    )

    payload, header = JWT.decode(
      result.access_token,
      secret,
      true,
      {
        algorithm: described_class::ALGORITHM,
        iss: described_class::ISSUER,
        verify_iss: true,
        aud: described_class::AUDIENCE,
        verify_aud: true,
        verify_expiration: false
      }
    )

    expect(result).to be_success
    expect(result.expires_at).to eq(now + described_class::ACCESS_TOKEN_TTL)
    expect(result.issued_at).to eq(now)
    expect(payload).to include(
      "sub" => user_id,
      "roles" => roles,
      "iat" => now.to_i,
      "exp" => result.expires_at.to_i,
      "iss" => described_class::ISSUER,
      "aud" => described_class::AUDIENCE
    )
    expect(payload.fetch("jti")).to be_present
    expect(header).to include("alg" => described_class::ALGORITHM)
  end

  it "accepts an explicit expiration for callers that already computed it" do
    expires_at = now + 5.minutes

    result = described_class.call(
      user: user,
      roles: roles,
      expires_at: expires_at,
      secret: secret,
      clock: -> { now }
    )

    payload, = JWT.decode(
      result.access_token,
      secret,
      true,
      algorithm: described_class::ALGORITHM,
      verify_expiration: false
    )

    expect(result.expires_at).to eq(expires_at)
    expect(payload.fetch("exp")).to eq(expires_at.to_i)
  end

  it "does not include email or password digest in the token payload" do
    result = described_class.call(
      user: user,
      roles: roles,
      secret: secret,
      clock: -> { now }
    )
    payload, = JWT.decode(
      result.access_token,
      secret,
      true,
      algorithm: described_class::ALGORITHM,
      verify_expiration: false
    )

    expect(payload.keys).not_to include("email", "password_digest")
  end
end
