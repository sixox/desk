class BallanceProjectsController < ApplicationController

  before_action :authenticate_user!
  before_action :find_project




  def new
    @ballance_project = BallanceProject.new
  end

  def create
    @ballance_project = BallanceProject.new(ballance_project_params)
    @ballance_project.project = @project
    respond_to do |format|

      if @ballance_project.save
        format.html { redirect_to project_url(@project), notice: "Allocate was successfully created." }
        format.json { render :show, status: :created, location: @project } 
      else
        render :new
      end
    end
  end

  private

  def find_project
    @project = Project.find(params[:project_id])
  end

  def ballance_project_params
    params.require(:ballance_project).permit(:ballance_id, :project_id, :quantity)
  end
end
