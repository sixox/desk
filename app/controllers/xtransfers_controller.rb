class XtransfersController < ApplicationController
  before_action :authenticate_user!

  before_action :set_xtransfer,
                only: [
                  :show,
                  :edit,
                  :update,
                  :destroy,
                  :toggle_pending,
                  :remove_document,
                  :remove_all_documents
                ]


  # ==================================================
  # INDEX
  # ==================================================

  def index
    scope = Xtransfer.all

    if params[:account_id].present?
      scope =
        scope
          .joins(:money_movements)
          .where(
            money_movements: {
              xaccount_id: params[:account_id]
            }
          )
          .distinct

      @account =
        Xaccount.find(
          params[:account_id]
        )
    end

    @xtransfers =
      scope
        .includes(
          :documents_attachments,

          money_movements: [
            :currency,
            :to_currency,
            {
              xaccount: [
                :organization,
                :currency
              ]
            }
          ],

          exchange_transfers: {
            exchange: {
              exchange_movements: [
                :currency,
                :to_currency,
                :xaccount
              ]
            }
          }
        )
        .order(
          created_at: :desc
        )
  end


  # ==================================================
  # SHOW
  # ==================================================

  def show
    @xtransfer =
      Xtransfer
        .includes(
          :documents_attachments,

          money_movements: [
            :currency,
            :to_currency,
            :xtransactions,
            {
              xaccount: [
                :currency,
                :organization
              ]
            }
          ],

          exchange_transfers: {
            exchange: {
              exchange_movements: [
                :currency,
                :to_currency,
                :xaccount
              ]
            }
          }
        )
        .find(
          params[:id]
        )
  end


  # ==================================================
  # NEW
  # ==================================================

  def new
    @xtransfer =
      Xtransfer.new(
        status: "completed",
        pending: false
      )

    @xtransfer.money_movements.build(
      direction: "send"
    )

    @xtransfer.money_movements.build(
      direction: "receive"
    )

    load_form_data

    @return_to =
      request.referer.presence ||
      xtransfers_path

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

      @xtransfer =
        Xtransfer.new(
          xtransfer_params
        )

      @xtransfer.save!

      attach_documents

      create_movement_transactions!(
        @xtransfer
      )
    end

    redirect_after_save(
      notice: "Transfer created successfully."
    )

  rescue ActiveRecord::RecordInvalid,
         ActiveRecord::RecordNotDestroyed,
         ActiveRecord::DeleteRestrictionError,
         ArgumentError => e

    @xtransfer ||=
      Xtransfer.new(
        xtransfer_params
      )

    add_base_error(
      @xtransfer,
      e
    )

    ensure_default_money_movements(
      @xtransfer
    )

    load_form_data

    @return_to =
      params[:return_to].presence ||
      xtransfers_path

    render :new,
           status: :unprocessable_entity
  end


  # ==================================================
  # EDIT
  # ==================================================

  def edit
    ensure_default_money_movements(
      @xtransfer
    )

    load_form_data

    @return_to =
      request.referer.presence ||
      xtransfers_path

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end


  # ==================================================
  # UPDATE
  # ==================================================

  def update
    ActiveRecord::Base.transaction do

      old_entries =
        capture_movement_entries(
          @xtransfer
        )

      old_movement_ids =
        old_entries.keys


      @xtransfer.update!(
        xtransfer_params
      )

      attach_documents


      reconcile_movement_transactions!(
        @xtransfer,
        old_entries,
        old_movement_ids
      )
    end

    redirect_after_save(
      notice: "Transfer updated successfully."
    )

  rescue ActiveRecord::RecordInvalid,
         ActiveRecord::RecordNotDestroyed,
         ActiveRecord::DeleteRestrictionError,
         ArgumentError => e

    add_base_error(
      @xtransfer,
      e
    )

    ensure_default_money_movements(
      @xtransfer
    )

    load_form_data

    @return_to =
      params[:return_to].presence ||
      request.referer.presence ||
      xtransfer_path(
        @xtransfer
      )

    render :edit,
           status: :unprocessable_entity
  end


  # ==================================================
  # DESTROY
  # ==================================================

  def destroy
    ActiveRecord::Base.transaction do
      @xtransfer.destroy!
    end

    redirect_to(
      xtransfers_path,
      notice: "Transfer deleted successfully."
    )

  rescue ActiveRecord::RecordNotDestroyed,
         ActiveRecord::DeleteRestrictionError,
         ActiveRecord::RecordInvalid,
         ArgumentError => e

    redirect_to(
      xtransfers_path,
      alert: e.message
    )
  end


  # ==================================================
  # TOGGLE PENDING
  # ==================================================

  def toggle_pending
    if @xtransfer.pending?
      @xtransfer.unset_pending!
    else
      @xtransfer.set_pending!
    end

    redirect_to xtransfers_path
  end


  # ==================================================
  # LOAD ACCOUNTS
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
      @xtransfer.documents.find_by(
        id: params[:document_id]
      )

    document&.purge

    redirect_to edit_xtransfer_path(
      @xtransfer
    )
  end


  # ==================================================
  # REMOVE ALL DOCUMENTS
  # ==================================================

  def remove_all_documents
    @xtransfer.documents.purge

    redirect_to edit_xtransfer_path(
      @xtransfer
    )
  end


  private


  # ==================================================
  # SET
  # ==================================================

  def set_xtransfer
    @xtransfer =
      Xtransfer.find(
        params[:id]
      )
  end


  # ==================================================
  # ATTACH DOCUMENTS
  # ==================================================

  def attach_documents
    documents =
      params.dig(
        :xtransfer,
        :documents
      )

    return if documents.blank?

    documents =
      Array(documents).reject(&:blank?)

    return if documents.empty?

    @xtransfer.documents.attach(
      documents
    )
  end


  # ==================================================
  # CREATE MOVEMENT TRANSACTIONS
  # ==================================================

  def create_movement_transactions!(xtransfer)
    xtransfer
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

  def capture_movement_entries(xtransfer)
    xtransfer
      .money_movements
      .reload
      .each_with_object({}) do |movement, entries|

        entries[movement.id] = {
          xaccount_id:
            movement.xaccount_id,

          currency_id:
            movement.currency_id,

          debit_amount:
            movement.debit_amount,

          credit_amount:
            movement.credit_amount
        }

      end
  end


  # ==================================================
  # RECONCILE MOVEMENTS
  # ==================================================

  def reconcile_movement_transactions!(
    xtransfer,
    old_entries,
    old_movement_ids
  )
    current_movements =
      xtransfer
        .money_movements
        .reload


    current_movements.each do |movement|

      old_entry =
        old_entries[
          movement.id
        ]


      # ------------------------------------------------
      # NEW MOVEMENT
      # ------------------------------------------------

      if old_entry.blank?

        Xtransaction.sync_movement!(
          movement: movement,
          user: current_user
        )

        next
      end


      # ------------------------------------------------
      # EXISTING MOVEMENT
      # ------------------------------------------------

      Xtransaction.sync_movement!(
        movement: movement,
        old_entry: old_entry,
        user: current_user
      )
    end


    # ------------------------------------------------
    # REMOVED MOVEMENTS
    #
    # We do not silently remove accounting history.
    # The surrounding transaction rolls everything back.
    # ------------------------------------------------

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
  # DEFAULT MOVEMENTS
  # ==================================================

  def ensure_default_money_movements(xtransfer)
    movements =
      xtransfer.money_movements


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

    @exchanges =
      Exchange
        .includes(
          exchange_movements: [
            :currency,
            :to_currency,
            :xaccount
          ]
        )
        .order(
          id: :desc
        )
  end


  # ==================================================
  # REDIRECT
  # ==================================================

  def redirect_after_save(notice:)
    return_to =
      params[:return_to].presence


    if return_to.present? &&
       return_to.start_with?("/")

      redirect_to(
        return_to,
        notice: notice
      )

    else

      redirect_to(
        xtransfers_path,
        notice: notice
      )

    end
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

  def xtransfer_params
    params
      .require(:xtransfer)
      .permit(
        :status,
        :pending,

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
        ],

        exchange_transfers_attributes: [
          :id,
          :exchange_id,
          :_destroy
        ]
      )
  end
end