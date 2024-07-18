class BallancesController < ApplicationController
	before_action :authenticate_user!
	before_action :set_ballance, only: %i[ show edit update destroy ]

	def show
		@spi = @ballance.spi if @ballance.spi
		@scis = @ballance.scis if @ballance.scis
		@allocates = @ballance.ballance_projects
		@remains = @ballance.remaining_quantity
		filtered_payment_orders = @ballance.payment_orders
		@payment_orders_with_status_paid_dollar = filtered_payment_orders.where(status: ['wait for delivery', 'delivered'], currency: 'dollar')
		@payment_orders_with_status_paid_dirham = filtered_payment_orders.where(status: ['wait for delivery', 'delivered'], currency: 'dirham')
		@payment_orders_with_status_paid_rial = filtered_payment_orders.where(status: ['wait for delivery', 'delivered'], currency: 'rial')
		@sum_paid_dollar = @payment_orders_with_status_paid_dollar.sum(:amount)
		@sum_paid_dirham = @payment_orders_with_status_paid_dirham.sum(:amount)
		@sum_paid_rial = @payment_orders_with_status_paid_rial.sum(:amount)
		@payment_orders_with_status_not_paid = filtered_payment_orders.where.not(status: ['wait for delivery', 'delivered'])

	end

	def index
		@q = Ballance.ransack(params[:q])
		@sort_column = params[:sort] || 'number'
		@ballances = @q.result.order(@sort_column => :desc)
	end

	def new	
		@ballance = Ballance.new
	end

	def create
		@ballance = Ballance.new(ballance_params)
		respond_to do |format|
			if @ballance.save
				format.html { redirect_to ballance_url(@ballance), notice: "Inventory was successfully created." }
				format.json { render :show, status: :created, location: @ballance }
			else
				format.turbo_stream { render turbo_stream: turbo_stream.replace('remote_modal', partial: 'shared/turbo_modal', locals: { form_partial: 'ballances/form', modal_title: 'Add new Balance' })}
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

	def set_ballance
		@ballance = Ballance.find(params[:id])
	end

	def ballance_params
		params.require(:ballance).permit(:number, :status, :name, :product, :supplier_id)
	end



end