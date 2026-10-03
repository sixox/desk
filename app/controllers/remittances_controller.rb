class RemittancesController < ApplicationController
  before_action :authenticate_user!

  before_action :set_remittance,
                only: [
                  :edit,
                  :update,
                  :destroy,
                  :remove_document,
                  :remove_all_documents
                ]


  # ==================================================
  # INDEX
  # ==================================================

  def index
    @remittances =
      Remittance
        .includes(
          :documents_attachments,
          money_movements: [
            :currency,
            :to_currency,
            :xtransactions,
            {
              xaccount: [
                :organization,
                :currency
              ]
            }
          ]
        )
        .order(
          created_at: :desc
        )
  end


  # ==================================================
  # NEW
  # ==================================================

  def new
    @remittance =
      Remittance.new

    build_default_movements

    load_form_data

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end


  # ==================================================
  # CREATE
  # ==================================================

  def create
    ActiveRecord::Base.transaction do
      @remittance =
        Remittance.new(
          remittance_params
        )

      @remittance.save!

      attach_documents

      create_movement_transactions!(
        @remittance
      )
    end

    redirect_to(
      remittances_path,
      notice: "Remittance created successfully."
    )

  rescue ActiveRecord::RecordInvalid,
         ActiveRecord::RecordNotDestroyed,
         ActiveRecord::DeleteRestrictionError,
         ArgumentError => e

    @remittance ||=
      Remittance.new(
        remittance_params
      )

    add_base_error(
      @remittance,
      e
    )

    ensure_default_movements(
      @remittance
    )

    load_form_data

    render(
      :new,
      status: :unprocessable_entity
    )
  end


  # ==================================================
  # EDIT
  # ==================================================

  def edit
    ensure_default_movements(
      @remittance
    )

    load_form_data
  end


  # ==================================================
  # UPDATE
  # ==================================================

  def update
    ActiveRecord::Base.transaction do

      old_entries =
        capture_movement_entries(
          @remittance
        )

      old_movement_ids =
        old_entries.keys


      @remittance.update!(
        remittance_params
      )

      attach_documents

      reconcile_movement_transactions!(
        @remittance,
        old_entries,
        old_movement_ids
      )
    end

    redirect_to(
      remittances_path,
      notice: "Remittance updated successfully."
    )

  rescue ActiveRecord::RecordInvalid,
         ActiveRecord::RecordNotDestroyed,
         ActiveRecord::DeleteRestrictionError,
         ArgumentError => e

    add_base_error(
      @remittance,
      e
    )

    ensure_default_movements(
      @remittance
    )

    load_form_data

    render(
      :edit,
      status: :unprocessable_entity
    )
  end


  # ==================================================
  # DESTROY
  # ==================================================

  def destroy
    ActiveRecord::Base.transaction do
      @remittance.destroy!
    end

    redirect_to(
      remittances_path,
      notice: "Remittance deleted successfully."
    )

  rescue ActiveRecord::RecordNotDestroyed,
         ActiveRecord::DeleteRestrictionError,
         ActiveRecord::RecordInvalid,
         ArgumentError => e

    redirect_to(
      remittances_path,
      alert: e.message
    )
  end


  # ==================================================
  # ACCOUNTS
  # ==================================================

  def accounts
    organization =
      Organization.find(
        params[:organization_id]
      )

    accounts =
      organization
        .xaccounts
        .includes(:currency)
        .order(:number)

    render json:
      accounts.map do |account|
        {
          id: account.id,
          number: account.number,
          kind: account.kind,
          currency_id: account.currency_id,
          currency_name: account.currency&.name,
          organization_name: organization.name,
          organization_kind: organization.kind
        }
      end
  end


  # ==================================================
  # REMOVE DOCUMENT
  # ==================================================

  def remove_document
    document =
      @remittance.documents.find(
        params[:document_id]
      )

    document.purge

    redirect_to(
      edit_remittance_path(@remittance),
      notice: "Attachment removed."
    )
  end


  # ==================================================
  # REMOVE ALL DOCUMENTS
  # ==================================================

  def remove_all_documents
    @remittance.documents.purge

    redirect_to(
      edit_remittance_path(@remittance),
      notice: "All attachments removed."
    )
  end


  private


  # ==================================================
  # SET
  # ==================================================

  def set_remittance
    @remittance =
      Remittance.find(
        params[:id]
      )
  end


  # ==================================================
  # CREATE MOVEMENT TRANSACTIONS
  # ==================================================

  def create_movement_transactions!(remittance)
    remittance
      .money_movements
      .reload
      .each do |movement|

        movement.create_xtransaction!(
          user: current_user
        )
      end
  end


  # ==================================================
  # CAPTURE OLD MOVEMENT ACCOUNTING
  # ==================================================

  def capture_movement_entries(remittance)
    remittance
      .money_movements
      .reload
      .each_with_object({}) do |movement, entries|

        entries[movement.id] = {
          xaccount_id: movement.xaccount_id,
          currency_id: movement.currency_id,
          debit_amount: movement.debit_amount,
          credit_amount: movement.credit_amount
        }

      end
  end


  # ==================================================
  # RECONCILE MOVEMENTS
  # ==================================================

  def reconcile_movement_transactions!(
    remittance,
    old_entries,
    old_movement_ids
  )
    current_movements =
      remittance
        .money_movements
        .reload


    current_movements.each do |movement|

      old_entry =
        old_entries[
          movement.id
        ]


      Xtransaction.sync_movement!(
        movement: movement,
        old_entry: old_entry,
        user: current_user
      )
    end


    current_movement_ids =
      current_movements.map(&:id)


    removed_ids =
      old_movement_ids -
      current_movement_ids


    return if removed_ids.empty?


    raise ActiveRecord::RecordNotDestroyed,
          "A movement with accounting history cannot be removed."
  end


  # ==================================================
  # ATTACHMENTS
  # ==================================================

  def attach_documents
    documents =
      params.dig(
        :remittance,
        :documents
      )

    return if documents.blank?

    documents =
      Array(documents).reject(&:blank?)

    return if documents.empty?

    @remittance.documents.attach(
      documents
    )
  end


  # ==================================================
  # DEFAULT MOVEMENTS
  # ==================================================

  def build_default_movements
    @remittance.money_movements.build(
      direction: "send"
    )

    @remittance.money_movements.build(
      direction: "receive"
    )
  end


  def ensure_default_movements(remittance)
    movements =
      remittance.money_movements


    has_send =
      movements.any? do |movement|
        movement.direction == "send"
      end


    has_receive =
      movements.any? do |movement|
        movement.direction == "receive"
      end


    unless has_send
      movements.build(
        direction: "send"
      )
    end


    unless has_receive
      movements.build(
        direction: "receive"
      )
    end
  end


  # ==================================================
  # FORM DATA
  # ==================================================

  def load_form_data
    @organizations =
      Organization.order(:name)

    @currencies =
      Currency.order(:name)
  end


  # ==================================================
  # ERROR
  # ==================================================

  def add_base_error(record, exception)
    record.errors.add(
      :base,
      exception.message
    )
  end


  # ==================================================
  # STRONG PARAMS
  # ==================================================

  def remittance_params
    params
      .require(:remittance)
      .permit(
        money_movements_attributes: [
          :id,
          :direction,
          :xaccount_id,
          :currency_id,
          :amount,
          :exchange_rate,
          :to_currency_id,
          :amount_to,
          :charge,
          :total,
          :_destroy
        ]
      )
  end
end