# frozen_string_literal: true

module Identity
  module Entities
    class User < Shared::Entities::BaseEntity
      attr_accessor :id,
                  :name,
                  :email,
                  :password_digest,
                  :email_confirmed_at,
                  :roles,
                  :created_at,
                  :updated_at
      
      def email_confirmed?
        email_confirmed_at.present?
      end

      def buyer?
        roles.include?('buyer')
      end

      def seller?
        roles.include?('seller')
      end
    end
  end
end
