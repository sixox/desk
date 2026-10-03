class ExchangesController < ApplicationController
  before_action :authenticate_user!

  before_action :set_exchange,
                only: [
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
    @exchanges =
      Exchange
        .includes(
          :documents_attachments,
          exchange_movements: [
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
    @exchange =
      Exchange.new

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

      @exchange =
        Exchange.new(
          exchange_params
        )

      @exchange.save!

      attach_documents

      create_movement_transactions!(
        @exchange
      )

      update_transfers
    end

    redirect_to(
      exchanges_path,
      notice: "Exchange created successfully."
    )

  rescue ActiveRecord::RecordInvalid,
         ActiveRecord::RecordNotDestroyed,
         ActiveRecord::DeleteRestrictionError,
         ArgumentError => e

    @exchange ||=
      Exchange.new(
        exchange_params
      )

    add_base_error(
      @exchange,
      e
    )

    ensure_default_movements(
      @exchange
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
      @exchange
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
          @exchange
        )

      old_movement_ids =
        old_entries.keys


      @exchange.update!(
        exchange_params
      )

      attach_documents

      reconcile_movement_transactions!(
        @exchange,
        old_entries,
        old_movement_ids
      )

      update_transfers
    end

    redirect_to(
      exchanges_path,
      notice: "Exchange updated successfully."
    )

  rescue ActiveRecord::RecordInvalid,
         ActiveRecord::RecordNotDestroyed,
         ActiveRecord::DeleteRestrictionError,
         ArgumentError => e

    add_base_error(
      @exchange,
      e
    )

    ensure_default_movements(
      @exchange
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
      @exchange.destroy!
    end

    redirect_to(
      exchanges_path,
      notice: "Exchange deleted successfully."
    )

  rescue ActiveRecord::RecordNotDestroyed,
         ActiveRecord::DeleteRestrictionError,
         ActiveRecord::RecordInvalid,
         ArgumentError => e

    redirect_to(
      exchanges_path,
      alert: e.message
    )
  end


  # ==================================================
  # PENDING
  # ==================================================

  def toggle_pending
    if @exchange.pending?
      @exchange.unset_pending!
    else
      @exchange.set_pending!
    end

    redirect_to exchanges_path
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
      @exchange.documents.find(
        params[:document_id]
      )

    document.purge

    redirect_to(
      edit_exchange_path(@exchange),
      notice: "Attachment removed."
    )
  end


  # ==================================================
  # REMOVE ALL DOCUMENTS
  # ==================================================

  def remove_all_documents
    @exchange.documents.purge

    redirect_to(
      edit_exchange_path(@exchange),
      notice: "All attachments removed."
    )
  end


  private


  # ==================================================
  # SET
  # ==================================================

  def set_exchange
    @exchange =
      Exchange.find(
        params[:id]
      )
  end


  # ==================================================
  # CREATE MOVEMENT TRANSACTIONS
  # ==================================================

  def create_movement_transactions!(exchange)
    exchange
      .exchange_movements
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

  def capture_movement_entries(exchange)
    exchange
      .exchange_movements
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
    exchange,
    old_entries,
    old_movement_ids
  )
    current_movements =
      exchange
        .exchange_movements
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
        :exchange,
        :documents
      )

    return if documents.blank?

    documents =
      Array(documents).reject(&:blank?)

    return if documents.empty?

    @exchange.documents.attach(
      documents
    )
  end


  # ==================================================
  # DEFAULT MOVEMENTS
  # ==================================================

  def build_default_movements
    @exchange.exchange_movements.build(
      direction: "sell"
    )

    @exchange.exchange_movements.build(
      direction: "buy"
    )
  end


  def ensure_default_movements(exchange)
    movements =
      exchange.exchange_movements


    has_sell =
      movements.any? do |movement|
        movement.direction == "sell"
      end


    has_buy =
      movements.any? do |movement|
        movement.direction == "buy"
      end


    unless has_sell
      movements.build(
        direction: "sell"
      )
    end


    unless has_buy
      movements.build(
        direction: "buy"
      )
    end
  end


  # ==================================================
  # RELATED TRANSFERS
  # ==================================================

  def update_transfers
    ids =
      exchange_params[:xtransfer_ids]


    ids =
      Array(ids)
        .reject(&:blank?)
        .map(&:to_i)
        .uniq


    @exchange.xtransfer_ids =
      ids
  end


  # ==================================================
  # FORM DATA
  # ==================================================

  def load_form_data
    @organizations =
      Organization.order(:name)

    @currencies =
      Currency.order(:name)


    @finished_transfers =
      Xtransfer
        .where.not(
          status: "finished"
        )
        .includes(
          money_movements: [
            :currency,
            :to_currency,
            {
              xaccount: :organization
            }
          ]
        )
        .order(
          created_at: :desc
        )
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

  def exchange_params
    params
      .require(:exchange)
      .permit(
        :kind,
        :wage,
        :pending,

        xtransfer_ids: [],

        exchange_movements_attributes: [
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