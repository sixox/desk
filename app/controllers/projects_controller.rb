class ProjectsController < ApplicationController
	
	before_action :authenticate_user!
	before_action :set_project, only: %i[ show edit update destroy ]


	def show
		@pi = @project.pi if @project.pi

	end

	def index
	end

	def new	
		@project = Project.new
	end

	def create
		@project = Project.new(project_params)
		respond_to do |format|
			if @project.save
				format.html { redirect_to project_url(@project), notice: "Project was successfully created." }
				format.json { render :show, status: :created, location: @project }
			else
				format.turbo_stream { render turbo_stream: turbo_stream.replace('remote_modal', partial: 'shared/turbo_modal', locals: { form_partial: 'projects/form', modal_title: 'Add new Project' })}
			end
		end
	end

	def edit
	end

	def update
	end

	def destroy
	end


	private

	def set_project
		@project = Project.find(params[:id])
	end

	def project_params
		params.require(:project).permit(:number, :status, :name)
	end




end
