class MerchOrdersController < ApplicationController
  
  def new
    @merch_order = MerchOrder.new(highlight_id: params[:highlight_id])
    @highlight = Highlight.find(params[:highlight_id]) if params[:highlight_id]

    @existing_orders = current_user.merch_orders.where(highlight_id: @highlight.id).index_by(&:product_type)
  end

  def create
    @merch_order = current_user.merch_orders.build(merch_order_params)

    if @merch_order.save
      redirect_to merch_order_path(@merch_order), notice: "Pre-order placed!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def merch_order_params
    params.require(:merch_order).permit(:highlight_id, :product_type, :design_text, :color, :quantity)
  end
end