class VacationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_vacation, only: %i[ edit update destroy ]

  def new
    @vacation = current_user.vacations.new
  end

  def edit
  end

  def create
  end

  def update
  end

  def destroy
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
