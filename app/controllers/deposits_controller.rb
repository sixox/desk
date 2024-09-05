class DepositsController < ApplicationController
	before_action :authenticate_user!

	def new
		@deposit = Deposit.new
		@banks = Bank.all
	end

	  def create
		  @banks = Bank.all
		  @bank = Bank.find(deposit_params[:bank_id])
		  @deposit = @bank.deposits.build(deposit_params) # You're building a deposit associated with the bank

		  ActiveRecord::Base.transaction do
		    @deposit.save! # Save the deposit first

		    # Now, create the associated transaction using @deposit
		    transaction = @deposit.transactions.create(
		      deposit_amount: @deposit.amount.to_i, 
		      bank: @bank,
		      balance_before_transaction: @bank.account_balance,
		      balance_after_transaction: @bank.account_balance.to_i + @deposit.amount.to_i
		    )

		    # Update the bank's balance
		    @bank.update!(account_balance: @bank.account_balance.to_i + @deposit.amount.to_i)
		  end

		  redirect_to @bank, notice: 'Deposit was successfully created.'
		rescue ActiveRecord::RecordInvalid
		  render :new
		end





	private

   

   

    def deposit_params
      params.require(:deposit).permit(:amount, :details, :bank_id, :document)
    end
end
