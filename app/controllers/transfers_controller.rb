class TransfersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_transfer, only: %i[ confirm reject ] 


  def new
    @transfer = Transfer.new
    @banks = Bank.all
  end

  def create
    @transfer = Transfer.new(transfer_params)
    @banks = Bank.all
    respond_to do |format|
      if @transfer.save
        format.html { redirect_to banks_path, notice: 'Transfer was successfully created' }
      else
        render :new
      end

    end
  end

  def confirm
    @transfer.confirmed = true
    @transfer.confirmed_at = Time.now
    if @transfer.valid?
      ActiveRecord::Base.transaction do
        @transfer.withdraw_from_bank.decrement!(:account_balance, @transfer.withdraw_amount)
        @transfer.deposited_to_bank.increment!(:account_balance, @transfer.deposited_amount)
        @transfer.save!
      end
      redirect_to banks_path, notice: 'Transfer confirmed successful'
    else
      render :new
    end

  end

  def reject
    @transfer.rejected = true
    @transfer.rejected_at = Time.now
    respond_to do |format|
      if @transfer.save
        format.html { redirect_to banks_path, notice: 'Transfer was rejected successfully' }
      else
        render :new
      end

    end

  end

  private

  def set_transfer
    @transfer = Transfer.find(params[:id])
  end

  def transfer_params
    params.require(:transfer).permit(:withdraw_from, :withdraw_amount, :deposited_to, :deposited_amount, :wage)
  end
end
