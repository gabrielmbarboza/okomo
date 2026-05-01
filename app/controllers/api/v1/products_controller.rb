# frozen_string_literal: true

class Api::V1::ProductsController < ApplicationController
  # Controller should be thin - just orchestrate requests
  # Business logic lives in domain services

  before_action :set_product_service

  # GET /api/v1/products
  def index
    if search_params[:q].present?
      @products = @product_service.search_products(search_params[:q])
    else
      @products = @product_service.list_active_products
    end

    render json: {
      success: true,
      data: @products.map(&:to_h),
      meta: {
        count: @products.size,
        search: search_params[:q]
      }
    }
  rescue StandardError => e
    handle_error(e, 'Failed to list products')
  end

  # GET /api/v1/products/:id
  def show
    @product = @product_service.get_product(params[:id])
    
    unless @product
      return render json: {
        success: false,
        error: 'Product not found'
      }, status: :not_found
    end

    render json: {
      success: true,
      data: @product.to_h
    }
  rescue ArgumentError => e
    render json: {
      success: false,
      error: e.message
    }, status: :bad_request
  rescue StandardError => e
    handle_error(e, 'Failed to get product')
  end

  # POST /api/v1/products
  def create
    @product = @product_service.create_product(product_params)

    render json: {
      success: true,
      data: @product.to_h,
      message: 'Product created successfully'
    }, status: :created
  rescue ArgumentError => e
    render json: {
      success: false,
      error: e.message
    }, status: :unprocessable_entity
  rescue StandardError => e
    handle_error(e, 'Failed to create product')
  end

  # PUT/PATCH /api/v1/products/:id
  def update
    @product = @product_service.update_product(params[:id], product_params)

    render json: {
      success: true,
      data: @product.to_h,
      message: 'Product updated successfully'
    }
  rescue ArgumentError => e
    render json: {
      success: false,
      error: e.message
    }, status: :unprocessable_entity
  rescue StandardError => e
    handle_error(e, 'Failed to update product')
  end

  # DELETE /api/v1/products/:id
  def destroy
    @product = @product_service.deactivate_product(params[:id])

    render json: {
      success: true,
      data: @product.to_h,
      message: 'Product deactivated successfully'
    }
  rescue ArgumentError => e
    render json: {
      success: false,
      error: e.message
    }, status: :unprocessable_entity
  rescue StandardError => e
    handle_error(e, 'Failed to deactivate product')
  end

  private

  def set_product_service
    @product_service = Catalog::Services::ProductService.new
  end

  def product_params
    params.require(:product).permit(
      :name,
      :description,
      :price,
      :sku,
      :status
    ).to_h.symbolize_keys
  end

  def search_params
    params.permit(:q)
  end

  def handle_error(error, message)
    Rails.logger.error "#{message}: #{error.message}"
    Rails.logger.error error.backtrace.join("\n") if Rails.env.development?

    render json: {
      success: false,
      error: Rails.env.production? ? message : "#{message}: #{error.message}"
    }, status: :internal_server_error
  end
end
