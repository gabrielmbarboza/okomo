# frozen_string_literal: true

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

      attr_accessor :id,
                    :user_id,
                    :display_name,
                    :description,
                    :status,
                    :document_type,
                    :document_number,
                    :legal_name,
                    :contact_email,
                    :contact_phone,
                    :commercial_address,
                    :requested_at,
                    :reviewed_at,
                    :reviewed_by_user_id,
                    :approved_at,
                    :rejected_at,
                    :rejection_reason,
                    :suspended_at,
                    :suspension_reason,
                    :created_at,
                    :updated_at

      def initialize(id:,
                     user_id:,
                     display_name:,
                     description: nil,
                     status: PENDING_REVIEW,
                     document_type: nil,
                     document_number: nil,
                     legal_name: nil,
                     contact_email: nil,
                     contact_phone: nil,
                     commercial_address: nil,
                     requested_at: nil,
                     reviewed_at: nil,
                     reviewed_by_user_id: nil,
                     approved_at: nil,
                     rejected_at: nil,
                     rejection_reason: nil,
                     suspended_at: nil,
                     suspension_reason: nil,
                     created_at: nil,
                     updated_at: nil)
        @id = id
        @user_id = user_id
        @display_name = display_name
        @description = description
        @status = status
        @document_type = document_type
        @document_number = document_number
        @legal_name = legal_name
        @contact_email = contact_email
        @contact_phone = contact_phone
        @commercial_address = commercial_address
        @requested_at = requested_at || Time.current
        @reviewed_at = reviewed_at
        @reviewed_by_user_id = reviewed_by_user_id
        @approved_at = approved_at
        @rejected_at = rejected_at
        @rejection_reason = rejection_reason
        @suspended_at = suspended_at
        @suspension_reason = suspension_reason
        @created_at = created_at || @requested_at
        @updated_at = updated_at || @created_at

        validate!
      end

      def validate!
        raise ArgumentError, "id cannot be nil" if @id.nil?
        raise ArgumentError, "user_id cannot be nil" if @user_id.nil?
        raise ArgumentError, "display_name cannot be nil or empty" if @display_name.blank?
        raise ArgumentError, "status must be one of: #{VALID_STATUSES.join(', ')}" unless VALID_STATUSES.include?(@status)
        if @document_type.present? && !VALID_DOCUMENT_TYPES.include?(@document_type)
          raise ArgumentError, "document_type must be one of: #{VALID_DOCUMENT_TYPES.join(', ')}"
        end
      end

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
