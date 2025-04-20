class MembersController < ApplicationController
	before_action :authenticate_user!, only: %i[show edit_description update_description edit_personal_details update_personal_details]

	def show
		@user = User.find(params[:id])
		@vacations_for_same_role = Vacation.joins(:user)
		.where(users: { role: @user.role })
		.where.not(users: { id: @user.id })
		@vacations = Vacation.all
		@fillers_grouped = fillers_grouped_by_year_and_period(@user)

		  @kpi_lists = if @user.procurement? && @user.is_manager?
					    KpiList.where(department: "COO")
					  elsif @user.admin?
					    KpiList.where(department: "IT")
					  elsif [20, 25, 71].include?(@user.id)
					    KpiList.where(department: "logestic")
					  elsif @user.ceo?
					    KpiList.where(department: "Board of Directors") 
					  elsif @user.id == 17
					  	KpiList.where(department: "Strategy & Dev")
					  elsif @user.id == 27
					  	KpiList.where(department: "AI & Investment")
					  else
					    KpiList.where(department: @user.role)
					  end



	end

	def edit_description

	end
	def update_description
		respond_to do |format|
			if current_user.update(about: params[:user][:about])
				format.turbo_stream { render turbo_stream: turbo_stream.replace('member-description', partial: 'members/member_description', locals: { user: current_user }) }
			end
		end
	end

	def edit_personal_details
	end
	def update_personal_details
		respond_to do |format|
			if current_user.update(user_personal_info_params)
				format.turbo_stream { render turbo_stream: turbo_stream.replace('member-personal-details', partial: 'members/member_personal_details', locals: { user: current_user }) }
			end
		end
	end

	def signatures
	    @users = User.all
	  end

	def update_signatures
	    @users = User.all
	    signatures_params.each do |user_id, signature|
	      user = User.find(user_id)
	      user.signature.attach(signature) if signature
	    end

	    redirect_to root_path, notice: "Signatures updated successfully."
    end



	private

	def user_personal_info_params
		params.require(:user).permit(:first_name, :last_name)
	end

	def signatures_params
      params.require(:signatures).permit!
	end

	def fillers_grouped_by_year_and_period(user)
	  # Fetch all unique year, period combinations and their fillers
	  user.assessment_forms_as_user
	      .select(:year, :period, :filler_id)
	      .includes(:filler)
	      .distinct
	      .group_by { |form| [form.year, form.period] }
	end


end	