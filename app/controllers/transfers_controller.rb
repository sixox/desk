class TransfersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_transfer, only: %i[ confirm reject ] 


  def export
    csv_data = Transaction.to_csv
    send_data csv_data, filename: "transactions-#{Date.today}.csv", type: "text/csv"
  end
  
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
  if current_user.ceo?
    @transfer.confirmed = true
    @transfer.confirmed_at = Time.now

    if @transfer.valid?
      ActiveRecord::Base.transaction do
        # Update bank balances
        @transfer.withdraw_from_bank.decrement!(:account_balance, @transfer.withdraw_amount)
        @transfer.deposited_to_bank.increment!(:account_balance, @transfer.deposited_amount)

        # Save the transfer
        @transfer.save!

        # Create transaction for the withdrawal bank
        @transfer.transactions.create!(
          withdrawal_amount: @transfer.withdraw_amount,
          bank: @transfer.withdraw_from_bank,
          balance_before_transaction: @transfer.withdraw_from_bank.account_balance.to_i + @transfer.withdraw_amount.to_i,
          balance_after_transaction: @transfer.withdraw_from_bank.account_balance.to_i
                )

        # Create transaction for the deposit bank
        @transfer.transactions.create!(
          deposit_amount: @transfer.deposited_amount,
          bank: @transfer.deposited_to_bank,
          balance_before_transaction: @transfer.deposited_to_bank.account_balance.to_i - @transfer.deposited_amount.to_i,
          balance_after_transaction: @transfer.deposited_to_bank.account_balance.to_i  
              )
      end

      redirect_to banks_path, notice: 'Transfer confirmed successfully'
    else
      render :new
    end
  else
    @transfer.coo_confirmed = true
    @transfer.coo_confirmed_at = Time.now
    if @transfer.save
      redirect_to banks_path, notice: 'Transfer confirmed successfully'
    else
      render :new
    end
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
    params.require(:transfer).permit(:withdraw_from, :withdraw_amount, :deposited_to, :deposited_amount, :wage, :document)
  end
end
