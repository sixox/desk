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
      scope = scope.where(
        "sender_account_id = :account_id OR receiver_account_id = :account_id",
        account_id: params[:account_id]
      )
      @account = Xaccount.find(params[:account_id])
    end

    @xtransfers =
      scope
        .includes(
          :sender_currency,
          :sender_to_currency,
          :receiver_currency,
          :receiver_to_currency,
          :documents_attachments,
          sender_account: [:organization, :currency],
          receiver_account: [:organization, :currency],
          exchange_transfers: {
            exchange: [
              :sell_currency,
              :buy_currency,
              { seller_account: :organization },
              { buyer_account: :organization }
            ]
          }
        )
        .order(created_at: :desc)
  end

  def show
    @xtransfer =
      Xtransfer
        .includes(
          :sender_currency,
          :sender_to_currency,
          :receiver_currency,
          :receiver_to_currency,
          :documents_attachments,
          :xtransactions,
          sender_account: [:currency, :organization],
          receiver_account: [:currency, :organization],
          exchange_transfers: {
            exchange: [
              :sell_currency,
              :buy_currency,
              { seller_account: :organization },
              { buyer_account: :organization }
            ]
          }
        )
        .find(params[:id])
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

    load_form_data

    @return_to =
      request.referer.presence ||
      xtransfers_path
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

      # ------------------------------------------------
      # Save transfer first.
      # ------------------------------------------------

      @xtransfer.save!

      # ------------------------------------------------
      # Attach documents separately.
      #
      # IMPORTANT:
      # Documents are intentionally NOT part of
      # xtransfer_params.
      #
      # This prevents Active Storage from replacing
      # existing attachments.
      # ------------------------------------------------

      attach_documents

      # ------------------------------------------------
      # Preload the accounts used by accounting_entries.
      #
      # This prevents Xtransfer#accounting_entries from
      # issuing separate account queries when the
      # associations are accessed.
      # ------------------------------------------------

      preload_accounting_accounts(
        @xtransfer
      )

      # ------------------------------------------------
      # Create initial accounting entries.
      #
      # Xtransfer describes its own accounting through
      # accounting_entries.
      #
      # Xtransaction remains generic.
      # ------------------------------------------------

      Xtransaction.create_for!(
        transactionable: @xtransfer,
        entries: @xtransfer.accounting_entries,
        user: current_user
      )
    end

    redirect_after_save(
      notice: "Transfer created successfully."
    )

  rescue ActiveRecord::RecordInvalid,
         ArgumentError => e

    @xtransfer ||=
      Xtransfer.new(
        xtransfer_params
      )

    @xtransfer.errors.add(
      :base,
      e.message
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

      # ------------------------------------------------
      # Preload both accounts before capturing the OLD
      # accounting state.
      #
      # This prevents repeated association queries.
      # ------------------------------------------------

      preload_accounting_accounts(
        @xtransfer
      )

      # ------------------------------------------------
      # Capture OLD accounting effect before changing
      # the Xtransfer.
      #
      # Plain hashes are duplicated so the old state
      # remains independent of the updated object.
      # ------------------------------------------------

      old_accounting_entries =
        @xtransfer
          .accounting_entries
          .map(&:dup)

      # ------------------------------------------------
      # Update Xtransfer.
      #
      # Documents are NOT passed to update!.
      # Existing attachments therefore remain untouched.
      # ------------------------------------------------

      @xtransfer.update!(
        xtransfer_params
      )

      # ------------------------------------------------
      # Attach ONLY newly uploaded documents.
      #
      # Existing documents are preserved.
      # ------------------------------------------------

      attach_documents

      # ------------------------------------------------
      # The account associations may have changed.
      #
      # Reset/reload them before calculating the NEW
      # accounting effect.
      # ------------------------------------------------

      @xtransfer.association(
        :sender_account
      ).reset

      @xtransfer.association(
        :receiver_account
      ).reset

      preload_accounting_accounts(
        @xtransfer
      )

      # ------------------------------------------------
      # Get NEW accounting effect.
      # ------------------------------------------------

      new_accounting_entries =
        @xtransfer.accounting_entries

      # ------------------------------------------------
      # Reconcile OLD vs NEW.
      #
      # This:
      #
      # - detects account changes
      # - detects amount changes
      # - detects total changes
      # - detects conversion changes
      # - detects charge effects
      # - applies old-account corrections
      # - applies new-account effects
      # - creates no transaction when accounting
      #   is unchanged
      #
      # ------------------------------------------------

      Xtransaction.reconcile!(
        transactionable: @xtransfer,
        old_entries: old_accounting_entries,
        new_entries: new_accounting_entries,
        user: current_user
      )
    end

    redirect_after_save(
      notice: "Transfer updated successfully."
    )

  rescue ActiveRecord::RecordInvalid,
         ArgumentError => e

    load_form_data

    @return_to =
      params[:return_to].presence ||
      request.referer.presence ||
      xtransfer_path(@xtransfer)

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

      # ------------------------------------------------
      # IMPORTANT:
      #
      # Historical accounting transactions are NOT
      # reversed or deleted here.
      #
      # Xtransaction records remain accounting history.
      # ------------------------------------------------

      @xtransfer.destroy!
    end

    redirect_to xtransfers_path,
                notice: "Transfer deleted successfully."

  rescue ActiveRecord::RecordNotDestroyed,
         ActiveRecord::RecordInvalid,
         ArgumentError => e

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

    html =
      accounts.map do |account|

        currency_name =
          account.currency&.name ||
          "No currency"

        %(
          <option
            value="#{
              ERB::Util.html_escape(
                account.id
              )
            }"
            data-currency-id="#{
              ERB::Util.html_escape(
                account.currency_id
              )
            }"
            data-currency-name="#{
              ERB::Util.html_escape(
                currency_name
              )
            }"
          >#{
            ERB::Util.html_escape(
              account.number
            )
          } - #{
            ERB::Util.html_escape(
              currency_name
            )
          }</option>
        )
      end.join

    render html:
      html.html_safe
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
  # SET TRANSFER
  # ==================================================

  def set_xtransfer
    @xtransfer =
      Xtransfer.find(
        params[:id]
      )
  end

  # ==================================================
  # ATTACH DOCUMENTS
  #
  # IMPORTANT:
  #
  # This method ONLY adds newly uploaded documents.
  #
  # It never replaces the existing Active Storage
  # attachments.
  #
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
  # PRELOAD ACCOUNTING ACCOUNTS
  #
  # Prevents Xtransfer#accounting_entries from
  # repeatedly loading sender/receiver accounts.
  #
  # ==================================================

  def preload_accounting_accounts(xtransfer)
    account_ids =
      [
        xtransfer.sender_account_id,
        xtransfer.receiver_account_id
      ]
        .compact
        .uniq

    return if account_ids.empty?

    accounts =
      Xaccount
        .where(
          id: account_ids
        )
        .includes(:currency)
        .index_by(&:id)

    if xtransfer.sender_account_id.present?

      xtransfer.association(
        :sender_account
      ).target =
        accounts[
          xtransfer.sender_account_id
        ]
    end

    if xtransfer.receiver_account_id.present?

      xtransfer.association(
        :receiver_account
      ).target =
        accounts[
          xtransfer.receiver_account_id
        ]
    end
  end

  # ==================================================
  # FORM DATA
  # ==================================================

  def load_form_data
    @organizations =
      Organization
        .order(:name)

    @currencies =
      Currency
        .order(:name)

    @exchanges =
      Exchange
        .includes(
          :sell_currency,
          :buy_currency,
          :seller_account,
          :buyer_account
        )
        .order(
          id: :desc
        )

    @sender_accounts =
      if @xtransfer.sender_account&.organization_id.present?

        Xaccount
          .where(
            organization_id:
              @xtransfer
                .sender_account
                .organization_id
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
              @xtransfer
                .receiver_account
                .organization_id
          )
          .includes(:currency)
          .order(:number)

      else

        Xaccount.none

      end
  end

  # ==================================================
  # REDIRECT AFTER SAVE
  # ==================================================

  def redirect_after_save(notice:)
    return_to =
      params[:return_to].presence

    if return_to.present? &&
       return_to.start_with?("/")

      redirect_to return_to,
                  notice: notice

    else

      redirect_to xtransfers_path,
                  notice: notice

    end
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
        ]

        # ----------------------------------------------
        # IMPORTANT:
        #
        # DO NOT add:
        #
        # documents: []
        #
        # Documents are attached separately through
        # attach_documents so existing attachments are
        # never replaced.
        # ----------------------------------------------

      )
  end
end