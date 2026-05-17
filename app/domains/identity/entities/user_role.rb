# frozen_string_literal: true

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
      attr_accessor :id,
                    :user_id,
                    :role_id,
                    :granted_at,
                    :revoked_at,
                    :granted_by_user_id,
                    :revoked_by_user_id,
                    :reason,
                    :created_at,
                    :updated_at

      def initialize(id:,
                     user_id:,
                     role_id:,
                     granted_at: nil,
                     revoked_at: nil,
                     granted_by_user_id: nil,
                     revoked_by_user_id: nil,
                     reason: nil,
                     created_at: nil,
                     updated_at: nil)
        @id = id
        @user_id = user_id
        @role_id = role_id
        @granted_at = granted_at || revoked_at || Time.current
        @revoked_at = revoked_at
        @granted_by_user_id = granted_by_user_id
        @revoked_by_user_id = revoked_by_user_id
        @reason = reason
        @created_at = created_at || @granted_at
        @updated_at = updated_at || @created_at

        validate!
      end

      def validate!
        raise ArgumentError, "user_id cannot be nil" if @user_id.nil?
        raise ArgumentError, "role_id cannot be nil" if @role_id.nil?
        raise ArgumentError, "granted_at cannot be nil" if @granted_at.nil?
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
