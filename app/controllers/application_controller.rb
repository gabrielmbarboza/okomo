# frozen_string_literal: true

class ApplicationController < ActionController::API
  # Controllers should only orchestrate requests.
  # Business logic must live in domain services (app/domains/<domain>/services/).
  #
  # Example:
  #   class Api::V1::OrdersController < ApplicationController
  #     def create
  #       result = Orders::Services::CreateOrder.call(order_params)
  #
  #       if result.success?
  #         render json: result.data, status: :created
  #       else
  #         render json: { errors: result.errors }, status: :unprocessable_entity
  #       end
  #     end
  #   end

  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from ActionController::ParameterMissing, with: :bad_request

  private

  def not_found
    render json: { error: "Resource not found" }, status: :not_found
  end

  def bad_request(exception)
    render json: { error: exception.message }, status: :bad_request
  end
end
