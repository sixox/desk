class BanksController < ApplicationController
  before_action :authenticate_user!
  before_action :set_bank, only: %i[show edit update destroy]

  def index
    @banks = Bank.all
  end

  def show
    @paid_payment_orders = @bank.payment_orders.joins(:receipt_attachment).where.not(active_storage_attachments: { id: nil })
    @waiting_payment_orders = @bank.payment_orders.where(status: 'wait for payment')
    @confirmed_swifts = @bank.swifts.where(confirmed: true)
    @unconfirmed_unrejected_swifts = @bank.swifts.where(confirmed: [nil, false], rejected: [nil, false])
  end

  def new
    @bank = Bank.new
  end

  def create
    @bank = Bank.new(bank_params)

    if @bank.save
      redirect_to @bank, notice: 'Bank was successfully created.'
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @bank.update(bank_params)
      redirect_to @bank, notice: 'Bank was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @bank.destroy
    redirect_to banks_url, notice: 'Bank was successfully destroyed.'
  end

  private

  def set_bank
    @bank = Bank.find(params[:id])
  end

  def bank_params
    params.require(:bank).permit(:name, :kind, :currency, :account_balance, :checked_balance)
  end
end
