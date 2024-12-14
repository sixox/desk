class SwiftsController < ApplicationController
	# before_action :set_swift, only: [:show, :edit, :update, :destroy]
	before_action :authenticate_user!
	before_action :set_ci_or_project, only: %i[ new create ] 
	before_action :set_swift, only: %i[ confirm reject edit_amount_before_confirm edit update destroy ] 


	def new
		if @object == 1
			@swift = @ci.build_swift
		else
			@swift = @project.swifts.build
		end
		@banks = Bank.all
	end

	def create
		if @object == 1
			@swift = @ci.build_swift(swift_params)
		else
			@swift = @project.swifts.build(swift_params)
		end
		@banks = Bank.all

		if @swift.save
			redirect_to swifts_path, notice: "Swift created successfully."
		else
			render :new
		end
	end

	def edit
		@projects = Project.all
		@banks = Bank.all
		if @swift.project.present?
			@object = 2
			@project = @swift.project
		else
			@object = 1
			@ci = @swift.ci
		end
	end

	def update
		updated_params = swift_params
		if updated_params[:documents].present? && updated_params[:documents].all?(&:blank?)
		   updated_params.delete(:documents)
		end
	    if @swift.update(updated_params)
	      redirect_to swifts_path, notice: 'Swift was successfully updated.'
	    else
	      render :edit
	    end
 	end
 	


	def edit_amount_before_confirm
		@banks = Bank.all
	end

	def index
	  # Create a Ransack query object
	  @q = Swift.with_bank_and_ci.ransack(params[:q])

	  # Perform the search using the Ransack query object
	  @swifts = @q.result.page(params[:page]).per(30)
	end

	def confirm
		  puts "Submitted params: #{swift_params.inspect}"

	  # Update @swift with the form's parameters
	  @swift.update(swift_params)

	  # Ensure @swift is confirmed and set the confirmation time
	  @swift.confirmed = true
	  @swift.confirm_at = Time.now

	  # Fetch the bank related to @swift
	  bank = @swift.bank
	  current_balance = bank.account_balance

	  # Calculate new amount using deposited_amount
	  new_amount = bank.account_balance.to_i + @swift.deposited_amount.to_i

	  # Save the swift and update the bank's account balance
	  if @swift.save && bank.update(account_balance: new_amount)
	  	transaction = @swift.transactions.create(
			      deposit_amount: @swift.deposited_amount.to_i , 
			      bank: bank,
			      balance_before_transaction: current_balance.to_i,
			      balance_after_transaction: new_amount.to_i
			    )
	    redirect_to swifts_path, notice: 'Swift confirmed successfully.'
	  else
	    render :show, status: :unprocessable_entity
	  end
	end


	def reject
		@swift.rejected = true
		@swift.rejected_at = Time.now
		respond_to do |format|
			if @swift.save
				format.html { redirect_to swifts_path, notice: 'Swift rejected successfully.' }
			else
				format.html { render :show, status: :unprocessable_entity }
				format.json { render json: @swift.errors, status: :unprocessable_entity }

			end
		end
	end

	def destroy
		respond_to do |format|
			@swift.destroy
	      	redirect_to swifts_path, notice: 'Swift was successfully removed.'
		end
	end




	private

	def set_swift
		@swift = Swift.find(params[:id])
	end

	def set_ci_or_project
		if params[:ci_id].present?
			@object = 1
			@ci = Ci.find(params[:ci_id])
		else
			@object = 2
			@project = Project.find(params[:project_id])
		end
	end

    # Only allow a list of trusted parameters through.
    def swift_params
    	params.require(:swift).permit(:amount, :bank_id, :currency, :confirmed, :rejected, :confirm_at, :rejected_at, :ci_id, :project_id, :deposited_amount, :from, :note, :advance, documents: [])
    end

end
