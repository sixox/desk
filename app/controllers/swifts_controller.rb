class SwiftsController < ApplicationController
	# before_action :set_swift, only: [:show, :edit, :update, :destroy]
	before_action :authenticate_user!
	before_action :set_ci

	def new
		@swift = @ci.build_swift
		@banks = Bank.all
	end

	def create
		@swift = @ci.build_swift(swift_params)
		if @swift.save
			redirect_to project_path(@ci.project), notice: "Swift created successfully."
		else
			render :new
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
