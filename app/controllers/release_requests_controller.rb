class ReleaseRequestsController < ApplicationController
  before_action :authenticate_user!

  before_action :authorize_project_workflow!,
    only: %i[new create]

  before_action :set_project_and_booking,
    only: %i[new create]

  before_action :set_release_request,
    only: :confirm

  before_action :authorize_accounting_confirmation!,
    only: :confirm


  def new
    if @booking.release_permission?
      redirect_to project_path(@project),
                  alert: "Release permission has already been granted."
      return
    end

    if @booking.release_request.present?
      redirect_to project_path(@project),
                  alert: "A release request already exists for this booking."
      return
    end

    @release_request = @booking.build_release_request

    respond_to do |format|
      format.turbo_stream

      format.html do
        render "shared/turbo_modal",
               layout: false,
               locals: release_request_modal_locals
      end
    end
  end


  def create
    if @booking.release_permission?
      redirect_to project_path(@project),
                  alert: "Release permission has already been granted."
      return
    end

    if @booking.release_request.present?
      redirect_to project_path(@project),
                  alert: "A release request already exists for this booking."
      return
    end

    @release_request = @booking.build_release_request(release_request_params)

    if @release_request.save
      redirect_to project_path(@project),
                  notice: "Release request created successfully.",
                  status: :see_other
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "remote_modal",
            partial: "shared/turbo_modal",
            locals: release_request_modal_locals
          ), status: :unprocessable_entity
        end

        format.html do
          render "shared/turbo_modal",
                 layout: false,
                 locals: release_request_modal_locals,
                 status: :unprocessable_entity
        end
      end
    end
  end


  def index
    @in_page = "index"
    @release_request_scope = ReleaseRequest.all

    load_release_requests
  end


  def unconfirmed
    @in_page = "unconfirmed"

    @release_request_scope =
      ReleaseRequest.where(confirmed: [nil, false])

    load_release_requests

    render :index
  end


  def confirm
    if @release_request.confirmed? &&
       @release_request.booking.release_permission?

      redirect_back fallback_location: unconfirmed_release_requests_path,
                    notice: "This release request has already been confirmed."
      return
    end

    @release_request.with_lock do
      @release_request.update!(
        confirmed: true,
        confirmed_at: @release_request.confirmed_at || Time.current
      )

      @release_request.booking.update!(
        release_permission: true,
        release_permission_date: Date.current
      )
    end

    redirect_back fallback_location: unconfirmed_release_requests_path,
                  notice: "Release request confirmed and booking permission granted."

  rescue ActiveRecord::RecordInvalid => e

    redirect_back fallback_location: unconfirmed_release_requests_path,
                  alert: e.record.errors.full_messages.to_sentence
  end


  private


  def set_project_and_booking
    @project = Project.find(params[:project_id])
    @booking = @project.bookings.find(params[:booking_id])
  end


  def set_release_request
    @release_request = ReleaseRequest.find(params[:id])
  end


  def authorize_project_workflow!
    allowed =
      current_user.admin? ||
      current_user.sales? ||
      current_user.logistics? ||
      current_user.ceo? ||
      current_user.cob? ||
      (current_user.is_manager && current_user.procurement?)

    head :forbidden unless allowed
  end


  def authorize_accounting_confirmation!
    head :forbidden unless current_user.accounting?
  end


  def load_release_requests
    @pending_count = ReleaseRequest.where(confirmed: [nil, false]).count
    @confirmed_count = ReleaseRequest.where(confirmed: true).count
    @all_count = ReleaseRequest.count

    scope = @release_request_scope
      .includes(booking: { project: { pi: :customer } })

    if params[:q].present?
      term = ActiveRecord::Base.sanitize_sql_like(params[:q].to_s.strip)
      search_term = "%#{term}%"
      request_id = term.match?(/\A\d+\z/) ? term.to_i : -1

      scope = scope
        .left_outer_joins(booking: { project: { pi: :customer } })
        .where(
          <<~SQL.squish,
            release_requests.id = :request_id
            OR bookings.number LIKE :term
            OR projects.number LIKE :term
            OR customers.nickname LIKE :term
            OR release_requests.note LIKE :term
          SQL
          request_id: request_id,
          term: search_term
        )
        .distinct
    end

    @release_requests = scope
      .order(created_at: :desc)
      .page(params[:page])
      .per(25)
  end


  def release_request_params
    params.require(:release_request).permit(:note)
  end


  def release_request_modal_locals
    {
      modal_title: "Request Release Permission",
      modal_subtitle: "Project #{@project.number} · Booking #{@booking.number}",
      modal_icon: "fa-file-signature",
      modal_size: "modal-md",
      form_partial: "release_requests/form",
      form_locals: {
        project: @project,
        booking: @booking,
        release_request: @release_request
      }
    }
  end
end