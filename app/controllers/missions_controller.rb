class MissionsController < ApplicationController
  def new
    @mission = current_user.missions.build
  end

  def create
    @mission = current_user.missions.build(mission_params)

    if @mission.save
      # Rails will render create.turbo_stream.erb automatically
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def mission_params
    params.require(:mission).permit(
      :start_at,
      :end_at,
      :mission_type,
      :description,
      :location,
      documents: []
      )
  end
end