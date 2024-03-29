class BallancesController < ApplicationController
	before_action :authenticate_user!
	before_action :set_ballance, only: %i[ show edit update destroy ]

	def show
		@spi = @ballance.spi if @ballance.spi
		@scis = @ballance.scis if @ballance.scis
		@allocates = @ballance.ballance_projects

	end

	def index
		@q = Ballance.ransack(params[:q])
		@ballances = @q.result.order(updated_at: :desc)
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