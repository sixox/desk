class XtransfersController < ApplicationController
  before_action :set_xtransfer,
                only: [
                  :edit,
                  :update,
                  :destroy,
                  :toggle_pending,
                  :remove_document,
                  :remove_all_documents
                ]

  def index
    @xtransfers = Xtransfer
      .includes(
        sender_account: :organization,
        receiver_account: :organization,
        exchanges: [
          :sell_currency,
          :buy_currency,
          seller_account: :organization,
          buyer_account: :organization
        ]
      )
      .order(created_at: :desc)
  end

  def new
    @xtransfer = Xtransfer.new
    load_form_data
  end

  def create
    @xtransfer = Xtransfer.new(xtransfer_params)

    Xtransfer.transaction do
      set_currencies

      @xtransfer.save!

      create_xtransactions_for_create

      attach_documents
    end

    redirect_to xtransfers_path, notice: "Transfer created."
  rescue ActiveRecord::RecordInvalid
    load_form_data
    render :new, status: :unprocessable_entity
  end

  def edit
    load_form_data
  end

  def update
    old_sender_account = @xtransfer.sender_account
    old_receiver_account = @xtransfer.receiver_account
    old_sent_amount = @xtransfer.sent_amount
    old_receive_amount = @xtransfer.receive_amount

    accounting_changed =
      old_sender_account.id != xtransfer_params[:sender_account_id].to_i ||
      old_receiver_account.id != xtransfer_params[:receiver_account_id].to_i ||
      old_sent_amount != xtransfer_params[:sent_amount].to_i ||
      old_receive_amount != xtransfer_params[:receive_amount].to_i

    Xtransfer.transaction do
      @xtransfer.update!(xtransfer_params)

      # Get currencies from the NEW accounts
      set_currencies
      @xtransfer.save!

      if accounting_changed
        update_accounts_and_create_xtransactions(
          old_sender_account,
          old_receiver_account,
          old_sent_amount,
          old_receive_amount
        )
      end

      attach_documents
    end

    redirect_to xtransfers_path, notice: "Transfer updated."
  rescue ActiveRecord::RecordInvalid
    load_form_data
    render :edit, status: :unprocessable_entity
  end

  def remove_document
    document = @xtransfer.documents.find(params[:document_id])
    document.purge

    redirect_to xtransfers_path
  end

  def remove_all_documents
    @xtransfer.documents.purge

    redirect_to xtransfers_path, notice: "All attachments removed."
  end

  def destroy
    @xtransfer.destroy

    redirect_to xtransfers_path, notice: "Transfer deleted."
  end

  def toggle_pending
    if @xtransfer.pending?
      @xtransfer.unset_pending!
    else
      @xtransfer.set_pending!
    end

    redirect_to xtransfers_path
  end

  def accounts
    organization = Organization.find(params[:organization_id])

    @accounts = organization.xaccounts.includes(:currency)

    render partial: "accounts", locals: { accounts: @accounts }
  end

  private

  def set_currencies
    sender_account = @xtransfer.sender_account
    receiver_account = @xtransfer.receiver_account

    return if sender_account.blank? || receiver_account.blank?

    @xtransfer.sender_currency = sender_account.currency
    @xtransfer.receiver_currency = receiver_account.currency
  end

  def set_xtransfer
    @xtransfer = Xtransfer.find(params[:id])
  end

  def load_form_data
    @organizations = Organization.order(:name)

    @exchanges = Exchange
      .includes(
        :sell_currency,
        :buy_currency,
        seller_account: :organization,
        buyer_account: :organization
      )
      .order(created_at: :desc)

    @sender_accounts =
      if @xtransfer.sender_account.present?
        @xtransfer.sender_account
          .organization
          .xaccounts
          .includes(:currency)
      else
        Xaccount.none
      end

    @receiver_accounts =
      if @xtransfer.receiver_account.present?
        @xtransfer.receiver_account
          .organization
          .xaccounts
          .includes(:currency)
      else
        Xaccount.none
      end
  end

  def xtransfer_params
    params.require(:xtransfer).permit(
      :sent_amount,
      :receive_amount,
      :exchange_rate,
      :wage,
      :sender_account_id,
      :receiver_account_id,
      :status,
      :pending,
      exchange_ids: []
    )
  end

  # ==================================================
  # CREATE ACCOUNTING TRANSACTIONS
  # ==================================================

  def create_xtransactions_for_create
    sender_account = @xtransfer.sender_account
    receiver_account = @xtransfer.receiver_account

    sender_before = sender_account.amount
    receiver_before = receiver_account.amount

    sender_after =
      sender_before - @xtransfer.sent_amount

    receiver_after =
      receiver_before + @xtransfer.receive_amount

    # Update account balances
    sender_account.update!(
      amount: sender_after
    )

    receiver_account.update!(
      amount: receiver_after
    )

    # Sender Xtransaction
    @xtransfer.xtransactions.create!(
      xaccount: sender_account,
      currency: sender_account.currency,
      withdrawal_amount: @xtransfer.sent_amount,
      balance_before_transaction: sender_before,
      balance_after_transaction: sender_after
    )

    # Receiver Xtransaction
    @xtransfer.xtransactions.create!(
      xaccount: receiver_account,
      currency: receiver_account.currency,
      deposit_amount: @xtransfer.receive_amount,
      balance_before_transaction: receiver_before,
      balance_after_transaction: receiver_after
    )
  end

  # ==================================================
  # UPDATE ACCOUNTING TRANSACTIONS
  # ==================================================

  def update_accounts_and_create_xtransactions(
    old_sender_account,
    old_receiver_account,
    old_sent_amount,
    old_receive_amount
  )
    # ----------------------------------------------
    # 1. Reverse old sender transaction
    # ----------------------------------------------

    old_sender_before = old_sender_account.amount

    old_sender_after =
      old_sender_before + old_sent_amount

    old_sender_account.update!(
      amount: old_sender_after
    )

    @xtransfer.xtransactions.create!(
      xaccount: old_sender_account,
      currency: old_sender_account.currency,
      deposit_amount: old_sent_amount,
      balance_before_transaction: old_sender_before,
      balance_after_transaction: old_sender_after
    )

    # ----------------------------------------------
    # 2. Reverse old receiver transaction
    # ----------------------------------------------

    old_receiver_before = old_receiver_account.amount

    old_receiver_after =
      old_receiver_before - old_receive_amount

    old_receiver_account.update!(
      amount: old_receiver_after
    )

    @xtransfer.xtransactions.create!(
      xaccount: old_receiver_account,
      currency: old_receiver_account.currency,
      withdrawal_amount: old_receive_amount,
      balance_before_transaction: old_receiver_before,
      balance_after_transaction: old_receiver_after
    )

    # ----------------------------------------------
    # 3. Apply new sender transaction
    # ----------------------------------------------

    new_sender_account = @xtransfer.sender_account

    new_sender_before = new_sender_account.amount

    new_sender_after =
      new_sender_before - @xtransfer.sent_amount

    new_sender_account.update!(
      amount: new_sender_after
    )

    @xtransfer.xtransactions.create!(
      xaccount: new_sender_account,
      currency: new_sender_account.currency,
      withdrawal_amount: @xtransfer.sent_amount,
      balance_before_transaction: new_sender_before,
      balance_after_transaction: new_sender_after
    )

    # ----------------------------------------------
    # 4. Apply new receiver transaction
    # ----------------------------------------------

    new_receiver_account = @xtransfer.receiver_account

    new_receiver_before = new_receiver_account.amount

    new_receiver_after =
      new_receiver_before + @xtransfer.receive_amount

    new_receiver_account.update!(
      amount: new_receiver_after
    )

    @xtransfer.xtransactions.create!(
      xaccount: new_receiver_account,
      currency: new_receiver_account.currency,
      deposit_amount: @xtransfer.receive_amount,
      balance_before_transaction: new_receiver_before,
      balance_after_transaction: new_receiver_after
    )
  end

  def attach_documents
    return if params[:xtransfer].blank?
    return if params[:xtransfer][:documents].blank?

    @xtransfer.documents.attach(
      params[:xtransfer][:documents]
    )
  end
end