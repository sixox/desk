class CisController < ApplicationController
	before_action :authenticate_user!
	before_action :find_project


	def new
	  @ci = @project.cis.build
	end

	def create
	@ci = @project.cis.build(ci_params)
	@ci.user = current_user
	@ci.pi = @project.pi
	if @ci.save
      redirect_to project_path(@project), notice: "CI created successfully."
    else
      render :new
    end



	end

	def edit
		@ci = Ci.find(params[:id])
	end

	
	def update
	  @ci = Ci.find(params[:id])
	  respond_to do |format|
	    if @ci.update(ci_params)
	      format.turbo_stream do
	        render turbo_stream: [
	          turbo_stream.replace("ci_item_#{@ci.id}", partial: 'cis/ci', locals: { ci: @ci, project: @ci.project }),
	          turbo_stream.update('notices', partial: 'shared/notices', locals: { notice: 'CI was successfully updated.' })
	        ]
	      end
	    else
	      format.turbo_stream do
	        render turbo_stream: [
	          turbo_stream.replace('remote_modal', partial: 'shared/turbo_modal', locals: { form_partial: 'cis/form', modal_title: 'Edit CI' }),
	          turbo_stream.update('notices', partial: 'shared/notices', locals: { alert: 'Error updating CI.' })
	        ]
	      end
	    end
	  end
	end


def destroy
    @ci = Ci.find(params[:id])

  respond_to do |format|
    @ci.destroy
    format.turbo_stream { render turbo_stream: turbo_stream.remove("ci_item_#{@ci.id}") }
  end
end

	private

	def ci_params
		params.require(:ci).permit(:net_weight, :gross_weight, :total_price, 
			:advance_payment, :balance_payment, :bank_account, :issue_date, 
			:project_id, :user_id, :document, :number, :validity
			)
	end

	def find_project
		@project = Project.find(params[:project_id])
	end



end
