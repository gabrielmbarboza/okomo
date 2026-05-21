require "rails_helper"

RSpec.describe Identity::Services::AuthorizeUser do
  subject(:service) do
    described_class.new(
      user: user,
      required_roles: required_roles,
      require_all: require_all
    )
  end

  let(:user_id) { SecureRandom.uuid }
  let(:required_roles) { [ Identity::Entities::Role::BUYER ] }
  let(:require_all) { false }
  let(:user) do
    Identity::Entities::User.new(
      id: user_id,
      email: "user@example.com",
      password_digest: "$2a$12$hash",
      status: Identity::Entities::User::ACTIVE,
      email_confirmed_at: Time.current,
      user_roles: user_roles
    )
  end
  let(:user_roles) do
    [
      Identity::Entities::UserRole.new(
        id: SecureRandom.uuid,
        user_id: user_id,
        role_id: Identity::Entities::Role::BUYER
      )
    ]
  end

  it "authorizes when user has any required effective role" do
    result = service.call

    expect(result).to be_success
    expect(result.user).to eq(user)
    expect(result.required_roles).to eq([ Identity::Entities::Role::BUYER ])
    expect(result.effective_roles).to eq([ Identity::Entities::Role::BUYER ])
    expect(result.matched_roles).to eq([ Identity::Entities::Role::BUYER ])
  end

  it "authorizes when user has all required effective roles" do
    user.grant_role(Identity::Entities::Role::SELLER)

    result = described_class.call(
      user: user,
      required_roles: [ Identity::Entities::Role::BUYER, Identity::Entities::Role::SELLER ],
      require_all: true
    )

    expect(result.matched_roles).to contain_exactly(
      Identity::Entities::Role::BUYER,
      Identity::Entities::Role::SELLER
    )
  end

  it "denies when user does not have the required role" do
    expect {
      described_class.call(user: user, required_roles: [ Identity::Entities::Role::SELLER ])
    }.to raise_error(described_class::AccessDenied, "user does not have required role")
  end

  it "denies when require_all is true and one role is missing" do
    expect {
      described_class.call(
        user: user,
        required_roles: [ Identity::Entities::Role::BUYER, Identity::Entities::Role::SELLER ],
        require_all: true
      )
    }.to raise_error(described_class::AccessDenied, "user does not have all required roles")
  end

  it "denies blocked users even when the role is assigned" do
    blocked_user = Identity::Entities::User.new(
      id: user_id,
      email: "user@example.com",
      password_digest: "$2a$12$hash",
      status: Identity::Entities::User::BLOCKED,
      email_confirmed_at: Time.current,
      user_roles: user_roles
    )

    expect {
      described_class.call(user: blocked_user, required_roles: [ Identity::Entities::Role::BUYER ])
    }.to raise_error(described_class::AccessDenied, "user has no effective roles")
  end

  it "denies users without confirmed email even when the role is assigned" do
    unconfirmed_user = Identity::Entities::User.new(
      id: user_id,
      email: "user@example.com",
      password_digest: "$2a$12$hash",
      status: Identity::Entities::User::ACTIVE,
      email_confirmed_at: nil,
      user_roles: user_roles
    )

    expect {
      described_class.call(user: unconfirmed_user, required_roles: [ Identity::Entities::Role::BUYER ])
    }.to raise_error(described_class::AccessDenied, "user has no effective roles")
  end

  it "rejects invalid required roles" do
    expect {
      described_class.call(user: user, required_roles: [ "moderator" ])
    }.to raise_error(described_class::InvalidRole, /required_roles must contain only/)
  end

  it "requires at least one role" do
    expect {
      described_class.call(user: user, required_roles: [])
    }.to raise_error(described_class::InvalidRole, "required_roles cannot be empty")
  end

  it "requires a user" do
    expect {
      described_class.call(user: nil, required_roles: [ Identity::Entities::Role::BUYER ])
    }.to raise_error(described_class::UserRequired, "user is required")
  end
end
