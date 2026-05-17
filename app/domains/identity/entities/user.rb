# frozen_string_literal: true

require "securerandom"

module Identity
  module Entities
    # User é o Aggregate Root do Bounded Context Identity.
    #
    # Representa uma conta de acesso à plataforma com autenticação via email e senha.
    #
    # Atributos:
    # - id: UUID único
    # - email: Email único, validado
    # - password_digest: Hash bcrypt da senha
    # - status: pending_confirmation, active, blocked, deactivated
    # - email_confirmed_at: timestamp de confirmação (nil = não confirmado)
    # - created_at, updated_at: timestamps
    #
    # Um User:
    # - Recebe automaticamente role 'buyer' após confirmação de email
    # - O role 'buyer' nunca pode ser revogado
    # - Pode ter um SellerProfile (um-para-um opcional)
    # - Pode ter múltiplos roles via UserRole (auditável)
    #
    # Estados:
    # - pending_confirmation: Email não confirmado, não pode fazer login
    # - active: Email confirmado, pode fazer login e comprar
    # - blocked: Bloqueado por violação, não pode fazer login
    # - deactivated: Desativado voluntariamente, não pode fazer login
    class User < Shared::Entities::BaseEntity
      PENDING_CONFIRMATION = 'pending_confirmation'
      ACTIVE = 'active'
      BLOCKED = 'blocked'
      DEACTIVATED = 'deactivated'

      VALID_STATUSES = [PENDING_CONFIRMATION, ACTIVE, BLOCKED, DEACTIVATED].freeze

      attr_accessor :id,
                    :name,
                    :email,
                    :password_digest,
                    :status,
                    :email_confirmed_at,
                    :last_login_at,
                    :user_roles,
                    :seller_profile,
                    :created_at,
                    :updated_at

      def initialize(id:,
                     email:,
                     password_digest:,
                     status: PENDING_CONFIRMATION,
                     name: nil,
                     email_confirmed_at: nil,
                     last_login_at: nil,
                     user_roles: [],
                     seller_profile: nil,
                     created_at: nil,
                     updated_at: nil)
        @id = id
        @name = name
        @email = email
        @password_digest = password_digest
        @status = status
        @email_confirmed_at = email_confirmed_at
        @last_login_at = last_login_at
        @user_roles = user_roles || []
        @seller_profile = seller_profile
        @created_at = created_at || Time.current
        @updated_at = updated_at || @created_at

        validate!
      end

      def validate!
        raise ArgumentError, "id cannot be nil" if @id.nil?
        raise ArgumentError, "email cannot be nil or empty" if @email.blank?
        raise ArgumentError, "password_digest cannot be nil or empty" if @password_digest.blank?
        raise ArgumentError, "status must be one of: #{VALID_STATUSES.join(', ')}" unless VALID_STATUSES.include?(@status)
      end

      # Verifica se o email foi confirmado
      def email_confirmed?
        @email_confirmed_at.present?
      end

      # Verifica se user está ativo (pode fazer login)
      def active?
        @status == ACTIVE
      end

      # Verifica se user está bloqueado
      def blocked?
        @status == BLOCKED
      end

      # Verifica se user está deativado
      def deactivated?
        @status == DEACTIVATED
      end

      # Verifica se user pode fazer login (ativo e com email confirmado)
      def can_login?
        active? && email_confirmed?
      end

      def confirm_email!(confirmed_at: Time.current)
        confirmation_time = @email_confirmed_at || confirmed_at

        @email_confirmed_at = confirmation_time
        @status = ACTIVE
        grant_role(
          Role::BUYER,
          granted_at: confirmation_time,
          reason: "automatic on email confirmation"
        ) unless has_role?(Role::BUYER)
        @updated_at = confirmed_at

        self
      end

      # Retorna todos os roles ativos do usuário
      def active_roles
        @user_roles.select(&:active?).map { |ur| ur.role_id }
      end

      # Verifica se user tem um role específico (ativo)
      def has_role?(role_name)
        @user_roles.any? { |ur| ur.active? && ur.role_id == role_name }
      end

      def grant_role(role_name, granted_by_user_id: nil, reason: nil, granted_at: Time.current)
        raise ArgumentError, "role_name must be one of: #{Role::VALID_NAMES.join(', ')}" unless Role::VALID_NAMES.include?(role_name)

        return active_user_role_for(role_name) if has_role?(role_name)

        user_role = UserRole.new(
          id: SecureRandom.uuid,
          user_id: @id,
          role_id: role_name,
          granted_at: granted_at,
          granted_by_user_id: granted_by_user_id,
          reason: reason
        )

        @user_roles << user_role
        @updated_at = granted_at

        user_role
      end

      def revoke_role(role_name, revoked_by_user_id: nil, reason: nil, revoked_at: Time.current)
        raise ArgumentError, "buyer role cannot be revoked" if role_name == Role::BUYER

        user_role = active_user_role_for(role_name)
        raise ArgumentError, "role is not active" unless user_role

        user_role.revoke!(
          revoked_by_user_id: revoked_by_user_id,
          reason: reason,
          revoked_at: revoked_at
        )
        @updated_at = revoked_at

        user_role
      end

      # Verifica se user é buyer
      def buyer?
        has_role?('buyer')
      end

      # Verifica se user é seller
      def seller?
        has_role?('seller')
      end

      # Verifica se user é admin
      def admin?
        has_role?('platform_admin')
      end

      # Verifica se user tem um SellerProfile
      def seller_profile?
        @seller_profile.present?
      end

      # Verifica se seller profile está aprovado
      def seller_approved?
        seller_profile? && @seller_profile.approved?
      end

      # Verifica se seller profile está suspenso
      def seller_suspended?
        seller_profile? && @seller_profile.suspended?
      end

      # Retorna quantos dias faltam para confirmação expirar (se ainda não confirmado)
      # Assumindo que tokens expiram em 24h
      def confirmation_expires_in_days
        return 0 if email_confirmed?
        days_remaining = 1 - ((Time.current - @created_at).to_f / 1.day)
        [days_remaining, 0].max
      end

      private

      def active_user_role_for(role_name)
        @user_roles.find { |user_role| user_role.active? && user_role.role_id == role_name }
      end
    end
  end
end
