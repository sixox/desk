class ProjectsController < ApplicationController
	
	before_action :authenticate_user!
	before_action :set_project, only: %i[ show edit update destroy allocate] 


	def show
		@pi = @project.pi if @project.pi
		@cis = @project.cis if @project.cis
		@bookings = @project.bookings if @project.bookings
		@allocates = @project.ballance_projects
		filtered_payment_orders = @project.payment_orders
		@payment_orders_with_status_paid_dollar = filtered_payment_orders.where(status: ['wait for delivery', 'delivered'], currency: 'dollar')
		@payment_orders_with_status_paid_dirham = filtered_payment_orders.where(status: ['wait for delivery', 'delivered'], currency: 'dirham')
		@payment_orders_with_status_paid_rial = filtered_payment_orders.where(status: ['wait for delivery', 'delivered'], currency: 'rial')
		@sum_paid_dollar = @payment_orders_with_status_paid_dollar.sum(:amount)
		@sum_paid_dirham = @payment_orders_with_status_paid_dirham.sum(:amount)
		@sum_paid_rial = @payment_orders_with_status_paid_rial.sum(:amount)

		@payment_orders_with_status_not_paid = filtered_payment_orders.where.not(status: ['wait for delivery', 'delivered'])



	end

	def index
		@q = Project.ransack(params[:q])
		@projects = @q.result.order(number: :desc)

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

	def allocate
	end




	private

	def set_project
		@project = Project.find(params[:id])
	end

	def project_params
		params.require(:project).permit(:number, :status, :name)
	end




end
