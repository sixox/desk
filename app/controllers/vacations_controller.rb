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
    format.html { redirect_to member_path(current_user), notice: 'Vacation confirmed successful' } 
  end
end


def index
  @vacations = current_user.vacations
end

def managment
  @users = User.all
  @user = current_user
  if @user.is_manager || @user.id == 10
    if @user.hr? || @user.procurement?  || @user.ceo? || @user.cob? || @user.id == 10
        @vacations = Vacation.all
    else
       @vacations = Vacation.joins(:user)
                        .where(users: { role: @user.role })
    end
  end
  @is_managment_page = true
  render 'index'
end

def by_user
      @users = User.all

      user_id = params[:user_id] || current_user.id
      @user = User.find(user_id)
      @vacations = @user.vacations
      @is_managment_page = true
      render 'index'

end


  def create
    @vacation = current_user.vacations.new(vacation_params)
    @vacation.confirm = true if current_user.is_manager
    respond_to do |format|
      if @vacation.save
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.prepend('vacation_items', partial: 'vacations/vacation', locals: { vacation: @vacation }),
            turbo_stream.update('notices', partial: 'shared/notices', locals: { notice: 'Vacation request was successfully created.' })
          ]
        end
      else
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace('remote_modal', partial: 'shared/turbo_modal', locals: { form_partial: 'vacations/form', modal_title: 'Create New Vacation Request' }),
            turbo_stream.update('notices', partial: 'shared/notices', locals: { alert: 'Error creating vacation request.' })
          ]
        end
      end
    end
  end


  def update
    respond_to do |format|
      if @vacation.update(vacation_params)
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace("vacation_item_#{@vacation.id}", partial: 'vacations/vacation', locals: { vacation: @vacation }),
            turbo_stream.update('notices', partial: 'shared/notices', locals: { notice: 'Vacation request was successfully updated.' })
          ]
        end
      else
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace('remote_modal', partial: 'shared/turbo_modal', locals: { form_partial: 'vacations/form', modal_title: 'Edit Vacation Request' }),
            turbo_stream.update('notices', partial: 'shared/notices', locals: { alert: 'Error updating vacation request.' })
          ]
        end
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
