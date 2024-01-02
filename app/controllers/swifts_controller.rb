class SwiftsController < ApplicationController
	# before_action :set_swift, only: [:show, :edit, :update, :destroy]
	before_action :authenticate_user!
	before_action :set_ci, only: %i[ new create ] 
	before_action :set_swift, only: %i[ confirm reject ] 


	def new
		@swift = @ci.build_swift
		@banks = Bank.all
	end

	def create
		@swift = @ci.build_swift(swift_params)
		@banks = Bank.all

		if @swift.save
			redirect_to project_path(@ci.project), notice: "Swift created successfully."
		else
			render :new
		end
	end

	def index
    	@swifts = Swift.with_bank_and_ci.all
	end

	def confirm
		@swift.confirmed = true
		@swift.confirm_at = Time.now
		bank = @swift.bank
		new_amount = bank.account_balance.to_i + @swift.amount.to_i
		respond_to do |format|
			if @swift.save && bank.update(account_balance: new_amount)
				format.html { redirect_to swifts_path }
			else
				format.html { render :show, status: :unprocessable_entity }
				format.json { render json: @swift.errors, status: :unprocessable_entity }

			end
		end
	end

	def reject
		@swift.rejected = true
		@swift.rejected_at = Time.now
		respond_to do |format|
			if @swift.save
				format.html { redirect_to swifts_path }
			else
				format.html { render :show, status: :unprocessable_entity }
				format.json { render json: @swift.errors, status: :unprocessable_entity }

			end
		end
	end




	private

	def set_swift
		@swift = Swift.find(params[:id])
	end

	def set_ci
		@ci = Ci.find(params[:ci_id])
	end

    # Only allow a list of trusted parameters through.
    def swift_params
    	params.require(:swift).permit(:amount, :bank_id, :currency, :confirmed, :rejected, :confirm_at, :rejected_at, :ci_id, documents: [])
    end

end
