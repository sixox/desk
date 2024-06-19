class BookingsController < ApplicationController
	before_action :authenticate_user!
	before_action :find_project
	before_action :set_booking, only: %i[ edit edit_picked_up edit_status shipping update_images update delete_all_images destroy] 

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
	end

	def edit_picked_up
	end

	def edit_status
	end

	def shipping
	end

	  def update
	    respond_to do |format|
	      if @booking.update(booking_params)
	        format.html { redirect_to project_path(@project), notice: 'Booking was successfully updated.' }
	        
	      else
	        format.html { render :edit }
	        
	      end
	    end
	  end

	  def update_images
	    if params[:booking][:images].present?
	      @booking.images.attach(params[:booking][:images])
	    end
	    redirect_to project_path(@project), notice: 'Images were successfully updated.'
	  end

	  def delete_all_images
	    @booking.images.purge
	    redirect_to project_path(@project), notice: 'All images were successfully deleted.'
	  end


def destroy

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
		:filled,
		:factory_order_date,
		:pick_up_date,
		:stuffing,
		:custom_clearance,
		:custom_submission_date,
		:vessel_eta,
		:part,
		:tally,
		:declaration,
		:vessel_name,
		:payment_done,
		:send_to_line,
		:bl_draft,
		:bl_dated,
		:surrender,
		images: []
		)
end

def set_booking
  @booking = Booking.find(params[:id])
end


def find_project
	@project = Project.find(params[:project_id])
end

end
