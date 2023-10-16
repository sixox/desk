class BookingsController < ApplicationController
	before_action :authenticate_user!
	before_action :find_project

	def new
		@booking = @project.bookings.build
	end

	def create
		@booking = @project.bookings.build(booking_params)
		if @booking.save
			redirect_to project_path(@project), notice: "booking created successfully."
		else
			render :new
		end



	end

	def edit
		@booking = Booking.find(params[:id])
	end

	def edit_picked_up
		@booking = Booking.find(params[:id])
	end

	def update
		@booking = Booking.find(params[:id])
		respond_to do |format|
			if @booking.update(booking_params)
				format.turbo_stream { render turbo_stream: turbo_stream.replace("booking_item_#{@booking.id}", partial: 'bookings/booking', locals: { booking: @booking, project: @booking.project }) }
			else
      # redirect_to root_path
      format.turbo_stream { render turbo_stream: turbo_stream.replace('remote_modal', partial: 'shared/turbo_modal', locals: { form_partial: 'bookings/form', modal_title: 'Edit booking' })}
  end
end
end

def destroy
	@booking = Booking.find(params[:id])

	respond_to do |format|
		@booking.destroy
		format.turbo_stream { render turbo_stream: turbo_stream.remove("booking_item_#{@booking.id}") }
	end
end

private

def booking_params
	params.require(:booking).permit(
		:number,
		:line,
		:forwarder,
		:pod,
		:container_type,
		:have_flexi,
		:quantity,
		:validation_date,
		:free_time,
		:status,
		:picked_up,
		:payment_status,
		:project_id,
		:filled
		)
end


def find_project
	@project = Project.find(params[:project_id])
end

end
