class LeadsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_lead, only: %i[edit update destroy update_status]

  def index
    @status = params[:status].presence
    @leads =
      Lead
        .includes(:owner)
        .yield_self { |rel| @status ? rel.where(status: Lead.statuses[@status]) : rel }
        .recent
     @my_due_count =
    LeadTask
      .where(assigned_to_id: current_user.id, status: :open)
      .where("due_on IS NULL OR due_on <= ?", Date.current)
      .count
  end

  def show
    @lead = Lead.includes(status_changes: :changed_by).find(params[:id])
  end

  def new
    @lead = Lead.new(owner: current_user)
  end

  def create
    @lead = Lead.new(lead_params.merge(owner: current_user))
    if @lead.save
      redirect_to leads_path, notice: "Lead created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def pipeline
    @status_order = %w[new_lead contacted responded offer_sent negotiation won lost]

    # Filter options
    @owners   = User.order(:name)                  # for the owner select
    @sources  = Lead.where.not(source: [nil, ""])
                     .distinct
                     .order(:source)
                     .pluck(:source)

    # Apply filters
    rel = Lead.includes(:owner).order(created_at: :desc)
    rel = rel.where(owner_id: params[:owner_id]) if params[:owner_id].present?
    rel = rel.where(source: params[:source])     if params[:source].present?

    @leads_by_status = rel.group_by(&:status)
  end

  def edit; end

  def update
    if @lead.update(lead_params)
      redirect_to leads_path, notice: "Lead updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @lead.destroy
    redirect_to leads_path, notice: "Lead deleted."
  end

  # Inline status switch; also accepts offer fields when moving to offer_sent
  def update_status
    @lead = Lead.find(params[:id])

    new_status = (params.dig(:lead, :status) || params[:status]).to_s.presence
    unless new_status
      return redirect_to leads_path(status: params[:back_status].presence), alert: "No status provided."
    end

    attrs = { status: new_status }

    if new_status == "offer_sent"
      attrs[:offered_amount] = params.dig(:lead, :offered_amount)
      attrs[:offered_on]     = params.dig(:lead, :offered_on)
    else
      attrs[:offered_amount] = nil
      attrs[:offered_on]     = nil
    end

    status_was = @lead.status

    if @lead.update(attrs)
      LeadStatusChange.create!(
        lead:          @lead,
        from_status:   status_was,
        to_status:     new_status,
        changed_by:    (respond_to?(:current_user) ? current_user : nil),
        occurred_at:   Time.current,
        offered_amount:(new_status == "offer_sent" ? @lead.offered_amount : nil)
      )
      redirect_to leads_path(status: params[:back_status].presence), notice: "Status updated."
    else
      redirect_to leads_path(status: params[:back_status].presence), alert: "Update failed."
    end
  end



  private

  def set_lead
    @lead = Lead.find(params[:id])
  end

  def lead_params
    params.require(:lead).permit(
      :name, :company, :phone, :email, :source, :notes,
      :owner_id, :status, :last_contact_on,
      :offered_amount, :offered_on
    )
  end

end
