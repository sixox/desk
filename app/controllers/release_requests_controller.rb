class ReleaseRequestsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_project_and_booking, only: [:new, :create]
  before_action :set_release_request, only: [:confirm]


  def new
    @release_request = @booking.build_release_request
  end

  def confirm
    if @release_request.update(confirmed: true, confirmed_at: Time.now)
      @release_request.booking.update(release_permission: true, release_permission_date: Time.now)
      redirect_to confirmable_payment_orders_path,
                  notice: "Release request confirmed successfully."
    else
      redirect_to confirmable_payment_orders_path,
                  alert: "Failed to confirm release request."
    end
  end


  def index
    @in_page = "index"
    
    @release_requests = ReleaseRequest.includes(booking: { project: :pi }).page(params[:page]).per(30)
  end

  def unconfirmed
    @in_page = "unconfirmed"

    # Filter release requests where confirmed is nil or false
    @release_requests = ReleaseRequest
                          .where(confirmed: [nil, false])
                          .includes(booking: { project: :pi })
                          .page(params[:page])
                          .per(30)

    render :index
  end

  def create
    @release_request = @booking.build_release_request(release_request_params)

    if @release_request.save
      redirect_to project_booking_path(@project, @booking), notice: "Release Request created successfully."
    else
      flash.now[:alert] = "Failed to create Release Request."
      render :new
    end
  end

  private

  def set_project_and_booking
    @project = Project.find(params[:project_id])
    @booking = @project.bookings.find(params[:booking_id])
  end

  def set_release_request
    @release_request = ReleaseRequest.find(params[:id])
  end

  def release_request_params
    params.require(:release_request).permit(:note)
  end
end
