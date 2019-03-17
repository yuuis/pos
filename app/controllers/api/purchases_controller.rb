# frozen_string_literal: true

class Api::PurchasesController < ApplicationController
  before_action :authenticate_admin_or_pos, only: %i[index show create check destroy]
  before_action :authenticate_admin_or_inventoryer, only: [:checkout]
  before_action :authenticate_admin_or_pos_or_arriver, only: [:aggregate]
  before_action :set_purchase, only: %i[show destroy]

  def index
    @purchases = Purchase.all
    render json: @purchases.to_json(methods: [:sales], include: { purchase_items: { only: %i[id product_id quantity price] } })
  end

  def show
    render json: @purchase.to_json(include: { purchase_items: { include: :product } })
  end

  def create
    @purchase = Purchase.new(create_params)
    params['products']&.map do |product|
      @purchase.purchase_items.new(create_purchase_item_params(product))
    end

    if @purchase.save
      @purchase.purchase_items.map(&:allocate_stock)
      @purchase.receipt_to_slack
      log_audit(@purchase, __method__)
      render json: { success: true, purchase: @purchase }, status: :created
    else
      render json: { success: false, errors: [@purchase.errors] }, status: :unprocessable_entity
    end
  end

  def check
    changed = false
    params['products'].each do |product|
      changed = true if Product.find(product[:product_id]).price != product[:price]
    end

    return render json: { success: false, errors: ['changed price.'] }, status: :ok if changed

    render json: { success: true, products: params['products'] }, status: :ok
  end

  def aggregate
    year = params[:year]
    month = params[:month]
    date = params[:date]
    product_id = params[:product_id]
    to = Time.at(params[:to]) if params[:to]
    from = Time.at(params[:from]) if params[:from]

    if year && month && date && product_id
      from = DateTime.new(year.to_i, month.to_i, date.to_i, 0, 0, 0)
      to = DateTime.new(year.to_i, month.to_i, date.to_i, 23, 59, 59)
      @purchases = Purchase.includes(:purchase_items).references(:purchase_items).where('purchase_items.product_id = ?', product_id).where('purchases.created_at BETWEEN ? AND ?', from, to)
    elsif year && month && date
      from = DateTime.new(year.to_i, month.to_i, date.to_i, 0, 0, 0, '+9')
      to = DateTime.new(year.to_i, month.to_i, date.to_i, 23, 59, 59, '+9')
      @purchases = Purchase.where('purchases.created_at BETWEEN ? AND ?', from, to)
    elsif year && month && product_id
      from = DateTime.new(year.to_i, month.to_i, 1)
      to = DateTime.new(year.to_i, month.to_i, -1)
      @purchases = Purchase.includes(:purchase_items).references(:purchase_items).where('purchase_items.product_id = ?', product_id).where('purchases.created_at BETWEEN ? AND ?', from, to)
    elsif year && month
      from = DateTime.new(year.to_i, month.to_i, 1)
      to = DateTime.new(year.to_i, month.to_i, -1)
      @purchases = Purchase.where('purchases.created_at BETWEEN ? AND ?', from, to)
    elsif year && product_id
      from = DateTime.new(year.to_i, 1, 1)
      to = DateTime.new(year.to_i, 12, -1)
      @purchases = Purchase.includes(:purchase_items).references(:purchase_items).where('purchase_items.product_id = ?', product_id).where('purchases.created_at BETWEEN ? AND ?', from, to)
    elsif year
      from = DateTime.new(year.to_i, 1, 1)
      to = DateTime.new(year.to_i, 12, -1)
      @purchases = Purchase.where('created_at BETWEEN ? AND ?', from, to)
    elsif month && product_id
      @purchases = Purchase.includes(:purchase_items).references(:purchase_items).where('purchase_items.product_id = ?', product_id).where('extract(month from purchases.created_at) = ?', month)
    elsif month
      @purchases = Purchase.where('extract(month from created_at) = ?', month)
    elsif product_id & to & from
      @purchases = Purchase.includes(:purchase_items).references(:purchase_items).where('purchase_items.product_id = ?', product_id).where('purchases.created_at BETWEEN ? AND ?', from, to)
    elsif product_id
      @purchases = Purchase.includes(:purchase_items).references(:purchase_items).where('purchase_items.product_id = ?', product_id)
    else
      @purchases = Purchase.all
    end
    render json: @purchases.to_json(methods: [:sales], include: { purchase_items: { only: %i[id product_id quantity price] } })
  end

  def destroy
    if @purchase&.cancel
      log_audit(@purchase, __method__)
      render json: { success: true, purchase: @purchase }, status: :no_content
    else
      render json: { success: false, errors: [@purchase.errors] }, status: :unprocessable_entity
    end
  end

  private

  def set_purchase
    @purchase = Purchase.find(params[:id])
  end

  def create_params
    params.require(:purchase).permit(:payment_uuid, :payment_method_id)
  end

  def create_purchase_item_params(params)
    params.permit(:product_id, :quantity, :price)
  end

  def log_audit(model, operation)
    AuditLog.create(model: 'purchase', model_id: model.id, operation: operation, operator: current_user.id)
  end
end
