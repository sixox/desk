class VacationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_vacation, only: %i[ edit update destroy ]

  def new
    @vacation = current_user.vacations.new
  end

  def edit
  end




  def edit_confirm_vacation
    vacation_id = params[:format].to_i
    @vacation = Vacation.find(vacation_id)

  end

  def update_confirm_vacation
    vacation_id = params[:format].to_i
    @vacation = Vacation.find(vacation_id)

    respond_to do |format|
      if @vacation.update(confirm: params[:vacation][:confirm])
        format.turbo_stream { render turbo_stream: turbo_stream.replace("vacation_item_#{@vacation.id}", partial: 'vacations/vacation', locals: { vacation: @vacation }) }
      else
        format.turbo_stream { render turbo_stream: turbo_stream.replace('remote_modal', partial: 'shared/turbo_modal', locals: { form_partial: 'vacations/form', modal_title: 'Edit Vacation Request' })}
      end
    end

  end



  

  def create
   @vacation = current_user.vacations.new(vacation_params)
   respond_to do |format|
    if @vacation.save
      format.turbo_stream { render turbo_stream: turbo_stream.prepend('vacation_items', partial: 'vacations/vacation', locals: { vacation: @vacation }) }
    else
      format.turbo_stream { render turbo_stream: turbo_stream.replace('remote_modal', partial: 'shared/turbo_modal', locals: { form_partial: 'vacations/form', modal_title: 'Create New Vacation Request' })}
    end
  end

end

def update
  respond_to do |format|
    if @vacation.update(vacation_params)
      format.turbo_stream { render turbo_stream: turbo_stream.replace("vacation_item_#{@vacation.id}", partial: 'vacations/vacation', locals: { vacation: @vacation }) }
    else
      format.turbo_stream { render turbo_stream: turbo_stream.replace('remote_modal', partial: 'shared/turbo_modal', locals: { form_partial: 'vacations/form', modal_title: 'Edit Vacation Request' })}
    end
  end
end

def destroy
  respond_to do |format|
    @vacation.destroy
    format.turbo_stream { render turbo_stream: turbo_stream.remove("vacation_item_#{@vacation.id}") }
  end
end




private
    # Use callbacks to share common setup or constraints between actions.
    def set_vacation
      @vacation = current_user.vacations.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def vacation_params
      params.require(:vacation).permit(:hourly, :status, :start_at, :end_at, :confirm, :user_id, :details, :comment, :vacation_type)
    end
  end
