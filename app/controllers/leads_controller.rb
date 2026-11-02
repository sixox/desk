
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
    @lead = Lead.includes(
      { status_changes: :changed_by },
      { lead_tasks: :assigned_to }
    ).find(params[:id])

    @task_assignees = User.by_name
  end

  def new
    @lead = Lead.new(owner: current_user)
  end

  
  def create
      @lead = Lead.new(lead_params.merge(owner: current_user))

      respond_to do |format|
        if @lead.save
          format.html do
            redirect_to leads_path, notice: "Lead created."
          end

          format.turbo_stream do
            redirect_to leads_path,
                        status: :see_other,
                        notice: "Lead created."
          end
        else
          format.html do
            render :new, status: :unprocessable_entity
          end

          format.turbo_stream do
            render turbo_stream: turbo_stream.replace(
              "remote_modal",
              partial: "shared/turbo_modal",
              locals: {
                modal_title: "New Lead",
                modal_subtitle: "Correct the highlighted information and try again.",
                modal_icon: "fa-user-plus",
                modal_size: "modal-lg",
                form_partial: "leads/form",
                form_locals: {
                  lead: @lead,
                  in_modal: true
                }
              }
            ), status: :unprocessable_entity
          end
        end
      end
    end


  
    def pipeline
      @status_order = Lead.statuses.keys

      @owners = User.by_name

      @sources = Lead.where.not(source: [nil, ""])
                     .distinct
                     .order(:source)
                     .pluck(:source)

      rel = Lead.includes(:owner, :lead_tasks).order(updated_at: :desc)

      rel = rel.where(owner_id: params[:owner_id]) if params[:owner_id].present?
      rel = rel.where(source: params[:source]) if params[:source].present?

      search = params[:q].to_s.strip

      if search.present?
        term = "%#{Lead.sanitize_sql_like(search)}%"

        rel = rel.where(
          "leads.name LIKE :term OR leads.company LIKE :term OR " \
          "leads.email LIKE :term OR leads.phone LIKE :term",
          term: term
        )
      end

      @leads_by_status = rel.to_a.group_by(&:status)
      @pipeline_counts = @leads_by_status.transform_values(&:size)

      @pipeline_total = @pipeline_counts.values.sum

      @pipeline_open_count = @status_order
        .reject { |status| %w[won lost].include?(status) }
        .sum { |status| @pipeline_counts.fetch(status, 0) }

      @pipeline_won_count = @pipeline_counts.fetch("won", 0)
      @pipeline_lost_count = @pipeline_counts.fetch("lost", 0)
    end


  def edit
  end

  
  def update
      respond_to do |format|
        if @lead.update(lead_params)
          format.html do
            redirect_to leads_path, notice: "Lead updated."
          end

          format.turbo_stream do
            redirect_to leads_path,
                        status: :see_other,
                        notice: "Lead updated."
          end
        else
          format.html do
            render :edit, status: :unprocessable_entity
          end

          format.turbo_stream do
            render turbo_stream: turbo_stream.replace(
              "remote_modal",
              partial: "shared/turbo_modal",
              locals: {
                modal_title: "Edit Lead",
                modal_subtitle: "Correct the highlighted information and try again.",
                modal_icon: "fa-user-pen",
                modal_size: "modal-lg",
                form_partial: "leads/form",
                form_locals: {
                  lead: @lead,
                  in_modal: true
                }
              }
            ), status: :unprocessable_entity
          end
        end
      end
    end


  def destroy
    @lead.destroy
    redirect_to leads_path, notice: "Lead deleted."
  end

  def update_status
    @lead = Lead.find(params[:id])

    new_status = (params.dig(:lead, :status) || params[:status]).to_s.presence

    unless new_status
      return redirect_to leads_path(status: params[:back_status].presence),
                         alert: "No status provided."
    end

    attrs = { status: new_status }

    if new_status == "offer_sent"
      attrs[:offered_amount] = params.dig(:lead, :offered_amount)
      attrs[:offered_on] = params.dig(:lead, :offered_on)
    else
      attrs[:offered_amount] = nil
      attrs[:offered_on] = nil
    end

    status_was = @lead.status

    if @lead.update(attrs)
      LeadStatusChange.create!(
        lead: @lead,
        from_status: status_was,
        to_status: new_status,
        changed_by: current_user,
        occurred_at: Time.current,
        offered_amount: (new_status == "offer_sent" ? @lead.offered_amount : nil)
      )

      redirect_to leads_path(status: params[:back_status].presence),
                  notice: "Status updated."
    else
      redirect_to leads_path(status: params[:back_status].presence),
                  alert: "Update failed."
    end
  end

  private

  def set_lead
    @lead = Lead.find(params[:id])
  end

  def lead_params
    params.require(:lead).permit(
      :name,
      :company,
      :phone,
      :email,
      :source,
      :notes,
      :owner_id,
      :status,
      :last_contact_on,
      :offered_amount,
      :offered_on
    )
  end
end
