class VacationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_vacation, only: %i[ edit update destroy ]

  def new
    @vacation = current_user.vacations.new
  end

  def edit
  end



  def confirm
    @vacation = Vacation.find(params[:id])
    @vacation.update(confirm: true)
    respond_to do |format|
    format.html { redirect_to member_path(current_user) } # Add this line for HTML response
  end
end





def create
 @vacation = current_user.vacations.new(vacation_params)
 @vacation.confirm = true if current_user.is_manager
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
      # redirect_to root_path
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
      @vacation = Vacation.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def vacation_params
      params.require(:vacation).permit(:hourly, :status, :start_at, :end_at, :confirm, :user_id, :details, :comment, :vacation_type)
    end
  end
