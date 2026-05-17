# frozen_string_literal: true

require "securerandom"

module Identity
  module Entities
    # SellerProfile representa o perfil de um vendedor na plataforma, incluindo
    # dados comerciais e status de moderação.
    #
    # Atributos:
    # - id: UUID único
    # - user_id: UUID do User associado (um-para-um)
    # - display_name: Nome público da loja
    # - description: Descrição opcional da loja
    # - status: pending_review, approved, rejected, suspended
    # - document_type: cpf, cnpj, mei
    # - document_number: Número do documento (criptografado em repouso)
    # - legal_name: Razão social ou nome legal
    # - contact_email: E-mail de contato comercial
    # - contact_phone: Telefone de contato
    # - commercial_address: Endereço comercial em JSON
    # - requested_at: Data da solicitação
    # - reviewed_at: Data da análise
    # - reviewed_by_user_id: UUID do admin que revisou
    # - approved_at: Data de aprovação
    # - rejected_at: Data de rejeição
    # - rejection_reason: Motivo da rejeição
    # - suspended_at: Data de suspensão
    # - suspension_reason: Motivo da suspensão
    # - created_at, updated_at: Timestamps
    class SellerProfile < Shared::Entities::BaseEntity
      PENDING_REVIEW = 'pending_review'
      APPROVED = 'approved'
      REJECTED = 'rejected'
      SUSPENDED = 'suspended'

      VALID_STATUSES = [PENDING_REVIEW, APPROVED, REJECTED, SUSPENDED].freeze

      DOC_TYPE_CPF = 'cpf'
      DOC_TYPE_CNPJ = 'cnpj'
      DOC_TYPE_MEI = 'mei'

      VALID_DOCUMENT_TYPES = [DOC_TYPE_CPF, DOC_TYPE_CNPJ, DOC_TYPE_MEI].freeze

      attribute :id, default: -> { SecureRandom.uuid }
      attributes :user_id,
                 :display_name,
                 :description,
                 :document_type,
                 :document_number,
                 :legal_name,
                 :contact_email,
                 :contact_phone,
                 :commercial_address,
                 :reviewed_at,
                 :reviewed_by_user_id,
                 :approved_at,
                 :rejected_at,
                 :rejection_reason,
                 :suspended_at,
                 :suspension_reason
      attribute :status, default: PENDING_REVIEW
      attribute :requested_at, default: -> { Time.current }
      attribute :created_at, default: ->(seller_profile) { seller_profile.requested_at }
      attribute :updated_at, default: ->(seller_profile) { seller_profile.created_at }

      validates :id, presence: { message: "id cannot be nil" }
      validates :user_id, presence: { message: "user_id cannot be nil" }
      validates :display_name, presence: true
      validates :status, inclusion: { in: VALID_STATUSES }
      validates :document_type, inclusion: { in: VALID_DOCUMENT_TYPES }

      # Verifica se SellerProfile está em revisão
      def pending_review?
        @status == PENDING_REVIEW
      end

      # Verifica se SellerProfile foi aprovado
      def approved?
        @status == APPROVED
      end

      # Verifica se SellerProfile foi rejeitado
      def rejected?
        @status == REJECTED
      end

      # Verifica se SellerProfile está suspenso
      def suspended?
        @status == SUSPENDED
      end

      # Verifica se SellerProfile pode vender (aprovado e não suspenso)
      def can_sell?
        approved?
      end

      def approve!(reviewed_by_user_id:, reviewed_at: Time.current)
        raise ArgumentError, "seller profile must be pending_review" unless pending_review?
        raise ArgumentError, "reviewed_by_user_id cannot be nil" if reviewed_by_user_id.nil?

        @status = APPROVED
        @reviewed_at = reviewed_at
        @reviewed_by_user_id = reviewed_by_user_id
        @approved_at = reviewed_at
        @rejected_at = nil
        @rejection_reason = nil
        @updated_at = reviewed_at

        self
      end

      def reject!(reviewed_by_user_id:, reason:, reviewed_at: Time.current)
        raise ArgumentError, "seller profile must be pending_review" unless pending_review?
        raise ArgumentError, "reviewed_by_user_id cannot be nil" if reviewed_by_user_id.nil?
        raise ArgumentError, "rejection_reason cannot be nil or empty" if reason.blank?

        @status = REJECTED
        @reviewed_at = reviewed_at
        @reviewed_by_user_id = reviewed_by_user_id
        @rejected_at = reviewed_at
        @rejection_reason = reason
        @updated_at = reviewed_at

        self
      end

      def suspend!(reason:, suspended_at: Time.current)
        raise ArgumentError, "seller profile must be approved" unless approved?
        raise ArgumentError, "suspension_reason cannot be nil or empty" if reason.blank?

        @status = SUSPENDED
        @suspended_at = suspended_at
        @suspension_reason = reason
        @updated_at = suspended_at

        self
      end

      def reactivate!(reactivated_at: Time.current)
        raise ArgumentError, "seller profile must be suspended" unless suspended?

        @status = APPROVED
        @approved_at ||= reactivated_at
        @suspended_at = nil
        @suspension_reason = nil
        @updated_at = reactivated_at

        self
      end

      # Retorna dias desde a solicitação
      def requested_days_ago
        ((Time.current - @requested_at) / 1.day).to_i
      end

      # Retorna dias desde aprovação (nil se não aprovado)
      def approved_days_ago
        return nil unless approved_at.present?
        ((Time.current - @approved_at) / 1.day).to_i
      end

      # Retorna dias de análise (desde solicitação até revisão)
      def review_duration_days
        return nil unless @reviewed_at.present?
        ((@reviewed_at - @requested_at) / 1.day).to_i
      end
    end
  end
end
