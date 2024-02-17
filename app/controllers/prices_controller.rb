class PricesController < ApplicationController

  before_action :authenticate_user!
  before_action :set_price, only: [:show, :edit, :update, :destroy, :add_price]

  def index
    # @prices = Price.all
    @q = Price.ransack(params[:q])
    @prices = @q.result.order(:created_at)
  end

  def show
  end

  def new
    @price = Price.new
  end

  def edit
  end

  def create
    @price = Price.new(price_params)
    @price.user = current_user 
    if @price.save
      redirect_to prices_url, notice: 'Price was successfully created.'
    else
      render :new
    end
  end

  def add_price
  end

  def update
    @price.historical_prices.create(
      quantity: @price.quantity,
      purchase_price: @price.purchase_price,
      fob_cost: @price.fob_cost,
      fob_price: @price.fob_price,
      time: @price.created_at,
      refinery: @price.refinery, 
      user_id: @price.user.id 
    )
    @price.user = current_user 
    if @price.update(price_params)

      redirect_to prices_url, notice: 'Price was successfully updated.'
    else
      render :add_price
    end
  end

  def destroy
    @price.destroy
    redirect_to prices_url, notice: 'Price was successfully destroyed.'
  end

  private
  def set_price
    @price = Price.find(params[:id])
  end

  def price_params
    params.require(:price).permit(:name, :packing, :oil_content, :refinery, :quantity, :purchase_price, :fob_cost, :fob_price, :description, :status, :user_id)
  end
end
