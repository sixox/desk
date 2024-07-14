class BallanceProjectsController < ApplicationController

  before_action :authenticate_user!
  before_action :find_ballance




  def new
    @ballance_project = BallanceProject.new
  end

  def create
    @ballance_project = BallanceProject.new(ballance_project_params)
    @ballance_project.ballance = @ballance
    respond_to do |format|

      if @ballance_project.save
        format.html { redirect_to ballance_url(@ballance), notice: "Allocate was successfully created." }
        format.json { render :show, status: :created, location: @ballance } 
      else
        render :new
      end
    end
  end

  private

  def find_ballance
    @ballance = Ballance.find(params[:ballance_id])
  end

  def ballance_project_params
    params.require(:ballance_project).permit(:ballance_id, :project_id, :quantity)
  end
end
