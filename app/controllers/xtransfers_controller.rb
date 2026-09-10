# app/controllers/xtransfers_controller.rb

class XtransfersController < ApplicationController
  before_action :set_xtransfer, only: [
    :edit,
    :update,
    :destroy,
    :toggle_pending,
    :remove_document,
    :remove_all_documents,
    :show
  ]


  # ==================================================
  # INDEX
  # ==================================================

  def index
    @xtransfers =
      Xtransfer
      .includes(
        :sender_currency,
        :sender_to_currency,
        :receiver_currency,
        :receiver_to_currency,
        :exchanges,
        sender_account: :organization,
        receiver_account: :organization
      )
      .order(created_at: :desc)
  end

  def show
  end


  # ==================================================
  # NEW
  # ==================================================

  def new
    @xtransfer = Xtransfer.new

    load_form_data
  end


  # ==================================================
  # CREATE
  # ==================================================

  def create
    ActiveRecord::Base.transaction do
      @xtransfer =
        Xtransfer.new(xtransfer_params)

      unless @xtransfer.save
        raise ActiveRecord::Rollback
      end

      Xtransaction.create_for_transfer!(
        transfer: @xtransfer
      )
    end

    if @xtransfer.persisted?
      redirect_to xtransfers_path,
                  notice: "Transfer created successfully."
    else
      load_form_data

      render :new,
             status: :unprocessable_entity
    end

  rescue ActiveRecord::RecordInvalid,
         ArgumentError => e

    @xtransfer ||= Xtransfer.new(xtransfer_params)

    @xtransfer.errors.add(
      :base,
      e.message
    )

    load_form_data

    render :new,
           status: :unprocessable_entity
  end


  # ==================================================
  # EDIT
  # ==================================================

  def edit
    load_form_data

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
      # ------------------------------------------------
      # Preserve old transactions before changing
      # the transfer.
      # ------------------------------------------------

      old_transactions =
        @xtransfer
        .xtransactions
        .lock
        .to_a


      # ------------------------------------------------
      # Reverse old accounting entries.
      #
      # We do not delete old transactions.
      # ------------------------------------------------

      old_transactions.each do |transaction|
        transaction.reverse!(
          transactionable: @xtransfer
        )
      end


      # ------------------------------------------------
      # Update transfer.
      # ------------------------------------------------

      unless @xtransfer.update(xtransfer_params)
        raise ActiveRecord::Rollback
      end


      # ------------------------------------------------
      # Create new accounting entries.
      # ------------------------------------------------

      Xtransaction.create_for_transfer!(
        transfer: @xtransfer
      )
    end

    redirect_to xtransfers_path,
                notice: "Transfer updated successfully."

  rescue ActiveRecord::RecordInvalid,
         ArgumentError => e

    load_form_data

    @xtransfer.errors.add(
      :base,
      e.message
    )

    render :edit,
           status: :unprocessable_entity
  end


  # ==================================================
  # DESTROY
  # ==================================================

  def destroy
    ActiveRecord::Base.transaction do
      # Reverse current accounting entries before
      # destroying the transfer.
      #
      # The reversal transactions use the same transfer
      # as their transactionable.
      @xtransfer
        .xtransactions
        .lock
        .to_a
        .each do |transaction|

        transaction.reverse!(
          transactionable: @xtransfer
        )
      end

      @xtransfer.destroy!
    end

    redirect_to xtransfers_path,
                notice: "Transfer deleted successfully."

  rescue ActiveRecord::RecordNotDestroyed => e

    redirect_to xtransfers_path,
                alert: e.message
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
    organization_id =
      params[:organization_id]

    accounts =
      if organization_id.present?
        Xaccount
          .where(
            organization_id: organization_id
          )
          .includes(:currency)
          .order(:number)
      else
        Xaccount.none
      end

    render html: accounts.map { |account|
      %(
        <option
          value="#{account.id}"
          data-currency-id="#{account.currency_id}"
          data-currency-name="#{ERB::Util.html_escape(account.currency.name)}"
        >
          #{ERB::Util.html_escape(account.number)}
          -
          #{ERB::Util.html_escape(account.currency.name)}
        </option>
      )
    }.join.html_safe
  end


  # ==================================================
  # REMOVE ONE DOCUMENT
  # ==================================================

  def remove_document
    document =
      @xtransfer.documents.find_by(
        id: params[:document_id]
      )

    document&.purge

    redirect_to edit_xtransfer_path(@xtransfer)
  end


  # ==================================================
  # REMOVE ALL DOCUMENTS
  # ==================================================

  def remove_all_documents
    @xtransfer.documents.purge

    redirect_to edit_xtransfer_path(@xtransfer)
  end


  private


  # ==================================================
  # SET TRANSFER
  # ==================================================

  def set_xtransfer
    @xtransfer =
      Xtransfer.find(params[:id])
  end


  # ==================================================
  # FORM DATA
  # ==================================================

  def load_form_data
    @organizations =
      Organization.order(:name)

    @exchanges =
      Exchange
      .includes(
        seller_account: :organization,
        buyer_account: :organization,
        sell_currency: {},
        buy_currency: {}
      )
      .order(created_at: :desc)


    @sender_accounts =
      if @xtransfer.sender_account&.organization_id.present?

        Xaccount
          .where(
            organization_id:
              @xtransfer.sender_account.organization_id
          )
          .includes(:currency)
          .order(:number)

      else

        Xaccount.none

      end


    @receiver_accounts =
      if @xtransfer.receiver_account&.organization_id.present?

        Xaccount
          .where(
            organization_id:
              @xtransfer.receiver_account.organization_id
          )
          .includes(:currency)
          .order(:number)

      else

        Xaccount.none

      end


    @currencies =
      Currency.order(:name)
  end


  # ==================================================
  # STRONG PARAMS
  # ==================================================

  def xtransfer_params
    params
      .require(:xtransfer)
      .permit(
        # ----------------------------------------------
        # Accounts
        # ----------------------------------------------

        :sender_account_id,
        :receiver_account_id,


        # ----------------------------------------------
        # Sender
        # ----------------------------------------------

        :sender_currency_id,
        :sender_to_currency_id,
        :sender_amount,
        :sender_exchange_rate,
        :sender_amount_to,
        :sender_charge,
        :sender_total,


        # ----------------------------------------------
        # Receiver
        # ----------------------------------------------

        :receiver_currency_id,
        :receiver_to_currency_id,
        :receiver_amount,
        :receiver_exchange_rate,
        :receiver_amount_to,
        :receiver_charge,
        :receiver_total,


        # ----------------------------------------------
        # Other
        # ----------------------------------------------

        :wage,
        :status,
        :pending,


        # ----------------------------------------------
        # Exchanges
        # ----------------------------------------------

        exchange_transfers_attributes: [
          :id,
          :exchange_id,
          :_destroy
        ],


        # ----------------------------------------------
        # Attachments
        # ----------------------------------------------

        documents: []
      )
  end
end