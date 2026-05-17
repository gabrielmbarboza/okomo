# frozen_string_literal: true

require "securerandom"

module Identity
  module Entities
    # UserRole representa a atribuição auditável de um Role a um User em um ponto
    # específico no tempo.
    #
    # A auditoria é feita através de:
    # - granted_at: quando o role foi concedido
    # - revoked_at: quando foi revogado (nil = ativo)
    # - granted_by_user_id: qual admin concedeu
    # - revoked_by_user_id: qual admin revogou
    # - reason: motivo da concessão ou revogação
    #
    # O role 'buyer' nunca pode ser revogado após atribuição.
    class UserRole < Shared::Entities::BaseEntity
      attribute :id, default: -> { SecureRandom.uuid }
      attributes :user_id,
                 :role_id,
                 :revoked_at,
                 :granted_by_user_id,
                 :revoked_by_user_id,
                 :reason
      attribute :granted_at, default: ->(user_role) { user_role.revoked_at || Time.current }
      attribute :created_at, default: ->(user_role) { user_role.granted_at }
      attribute :updated_at, default: ->(user_role) { user_role.created_at }

      validates :user_id, presence: { message: "user_id cannot be nil" }
      validates :role_id, presence: { message: "role_id cannot be nil" }
      validates :granted_at, presence: { message: "granted_at cannot be nil" }

      def validate!
        super
        raise ArgumentError, "revoked_at cannot be before granted_at" if @revoked_at && @revoked_at < @granted_at
      end

      # Verifica se este role está ativo para o usuário
      def active?
        @revoked_at.nil?
      end

      # Verifica se este role foi revogado
      def revoked?
        @revoked_at.present?
      end

      def buyer?
        @role_id == Role::BUYER
      end

      def revoke!(revoked_by_user_id: nil, reason: nil, revoked_at: Time.current)
        raise ArgumentError, "buyer role cannot be revoked" if buyer?
        raise ArgumentError, "role already revoked" if revoked?
        raise ArgumentError, "revoked_at cannot be before granted_at" if revoked_at < @granted_at

        @revoked_at = revoked_at
        @revoked_by_user_id = revoked_by_user_id
        @reason = reason if reason
        @updated_at = revoked_at

        self
      end

      # Retorna o tempo decorrido desde a concessão
      def granted_ago
        Time.current - @granted_at
      end

      # Retorna o tempo decorrido desde a revogação (nil se não revogado)
      def revoked_ago
        return nil unless @revoked_at
        Time.current - @revoked_at
      end

      # Retorna duração do role (desde concessão até revogação ou até agora)
      def duration
        end_time = @revoked_at || Time.current
        end_time - @granted_at
      end
    end
  end
end
