class BookingsController < ApplicationController
  before_action :authenticate_user!
  before_action :find_project

  before_action :set_booking,
    only: %i[
      edit
      edit_picked_up
      edit_status
      shipping
      update
      update_images
      delete_all_images
      destroy
    ]

  def new
    @booking = @project.bookings.build
    render_booking_form("New Booking")
  end

  def create
    @booking = @project.bookings.build(booking_params)

    if @booking.save
      redirect_to project_path(@project),
                  notice: "Booking created successfully."
    else
      @new_booking = @booking
      render "projects/show", status: :unprocessable_entity
    end
  end

  def update
    if @booking.update(booking_params)
      redirect_to project_path(@project),
                  notice: "Booking was successfully updated."
    else
      @bookings = @project.bookings.includes(:release_request).order(created_at: :desc).to_a
      @editing_booking_id = @booking.id

      index = @bookings.index { |record| record.id == @booking.id }
      @bookings[index] = @booking if index

      render "projects/show", status: :unprocessable_entity
    end
  end

  def edit
    render_booking_form("Edit Booking")
  end

  def edit_picked_up
  end

  def edit_status
  end

  def shipping
  end

  

  def update_images
    if params.dig(:booking, :images).present?
      @booking.images.attach(params[:booking][:images])
    end

    redirect_to project_path(@project),
                notice: "Booking images were updated successfully."
  end

  def delete_all_images
    @booking.images.purge

    redirect_to project_path(@project),
                notice: "Booking images were deleted."
  end

  def destroy
    @booking.destroy

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.remove(
          "booking_item_#{@booking.id}"
        )
      end

      format.html do
        redirect_to project_path(@project),
                    notice: "Booking was deleted."
      end
    end
  end

  private

  def find_project
    @project = Project.find(params[:project_id])
  end

  def set_booking
    @booking = @project.bookings.find(params[:id])
  end

  def render_booking_form(title, status: :ok)
    modal_locals = {
      form_partial: "bookings/form",
      modal_title: title,
      modal_subtitle: "Project #{@project.number}",
      modal_icon: "fa-truck-fast",
      modal_size: "modal-lg",
      form_locals: {
        project: @project,
        booking: @booking
      }
    }

    respond_to do |format|
      format.html do
        render "shared/turbo_modal",
               locals: modal_locals,
               status: status
      end

      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "remote_modal",
          partial: "shared/turbo_modal",
          locals: modal_locals
        ), status: status
      end
    end
  end

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
      :bl_number,
			:date_of_bl,
      :surrender,
      :release_permission,
      :release_permission_date,
      :inspection,
      :freight_price,
      :weight,
      images: []
    )
  end
end