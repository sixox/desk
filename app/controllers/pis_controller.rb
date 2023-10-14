class PisController < ApplicationController
  before_action :find_project

  def new
    @pi = @project.build_pi
  end

  def create
    @pi = @project.build_pi(pi_params)
    @pi.user = current_user
    if @pi.save
      redirect_to project_path(@project), notice: "PI created successfully."
    else
      render :new
    end
  end

  def edit
    @pi = Pi.find(params[:id])

  end

def update
  @pi = Pi.find(params[:id])
  respond_to do |format|
    if @pi.update(pi_params)
      format.turbo_stream { render turbo_stream: turbo_stream.replace("pi_item_#{@pi.id}", partial: 'pis/pi', locals: { pi: @pi, project: @pi.project }) }
    else
      # redirect_to root_path
      format.turbo_stream { render turbo_stream: turbo_stream.replace('remote_modal', partial: 'shared/turbo_modal', locals: { form_partial: 'pis/form', modal_title: 'Edit PI' })}
    end
  end
end

def destroy
    @pi = Pi.find(params[:id])

  respond_to do |format|
    @pi.destroy
    format.turbo_stream { render turbo_stream: turbo_stream.remove("vacation_item_#{@pi.id}") }
  end
end

private

def find_project
  @project = Project.find(params[:project_id])
end

def pi_params
  params.require(:pi).permit(
    :number, :product, :validity, :quantity, :unit_price, :payment_term,
    :bank_account, :packing_type, :packing_count, :shipment_rate, :seller,
    :delivery_time, :issue_date, :pol, :pod, :customer_id, :user_id, :project_id, :currency, 
    :total_price, :document
    )
end

end
