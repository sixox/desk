class RemittancesController < ApplicationController
  before_action :set_remittance,
                only: [
                  :edit,
                  :update,
                  :destroy,
                  :remove_document,
                  :remove_all_documents
                ]

  def index
    @remittances =
      Remittance
        .includes(
          :currency,
          sender_account: :organization,
          receiver_account: :organization
        )
        .order(created_at: :desc)
  end

  def new
    @remittance = Remittance.new
    load_form_data

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def create
    @remittance = Remittance.new(remittance_params)

    Remittance.transaction do
      @remittance.save!
      create_xtransactions_for_create
      attach_documents
    end

    redirect_to remittances_path,
                notice: "Remittance created successfully."
  rescue ActiveRecord::RecordInvalid
    load_form_data

    respond_to do |format|
      format.html { render :new, status: :unprocessable_entity }
      format.turbo_stream { render :new, status: :unprocessable_entity }
    end
  end

  def edit
    load_form_data
  end

  def update
    old_sender_account = @remittance.sender_account
    old_receiver_account = @remittance.receiver_account
    old_sent_amount      = @remittance.sent_amount
    old_received_amount  = @remittance.received_amount

    accounting_changed =
      old_sender_account.id != remittance_params[:sender_account_id].to_i ||
      old_receiver_account.id != remittance_params[:receiver_account_id].to_i ||
      old_sent_amount != remittance_params[:sent_amount].to_i ||
      old_received_amount != remittance_params[:received_amount].to_i

    Remittance.transaction do
      @remittance.update!(remittance_params)

      if accounting_changed
        update_accounts_and_create_xtransactions(
          old_sender_account,
          old_receiver_account,
          old_sent_amount,
          old_received_amount
        )
      end

      attach_documents
    end

    redirect_to remittances_path,
                notice: "Remittance updated successfully."
  rescue ActiveRecord::RecordInvalid
    load_form_data
    render :edit, status: :unprocessable_entity
  end

  def destroy
    @remittance.destroy

    redirect_to remittances_path,
                notice: "Remittance deleted successfully."
  end

  def accounts
    organization = Organization.find(params[:organization_id])

    accounts = organization.xaccounts.includes(:currency)

    render json: accounts.map { |account|
      {
        id: account.id,
        number: account.number,
        kind: account.kind,
        currency_name: account.currency.name,
        organization_name: organization.name,
        organization_kind: organization.kind
      }
    }
  end

  def remove_document
    document = @remittance.documents.find(params[:document_id])
    document.purge

    redirect_to edit_remittance_path(@remittance),
                notice: "Attachment removed."
  end

  def remove_all_documents
    @remittance.documents.purge

    redirect_to edit_remittance_path(@remittance),
                notice: "All attachments removed."
  end

  private

  def set_remittance
    @remittance = Remittance.find(params[:id])
  end

  def load_form_data
    @organizations = Organization.order(:name)
    @currencies = Currency.order(:name)

    @sender_accounts =
      if @remittance.sender_account.present?
        @remittance.sender_account.organization.xaccounts.includes(:currency)
      else
        Xaccount.none
      end

    @receiver_accounts =
      if @remittance.receiver_account.present?
        @remittance.receiver_account.organization.xaccounts.includes(:currency)
      else
        Xaccount.none
      end
  end

  def remittance_params
    params.require(:remittance).permit(
      :sender_account_id,
      :receiver_account_id,
      :sent_amount,
      :received_amount,
      :currency_id
    )
  end

  def attach_documents
    return if params[:remittance].blank?
    return if params[:remittance][:documents].blank?

    @remittance.documents.attach(params[:remittance][:documents])
  end

  # ==================================================
  # CREATE ACCOUNTING TRANSACTIONS
  # ==================================================

  def create_xtransactions_for_create
    sender_account   = @remittance.sender_account
    receiver_account = @remittance.receiver_account

    sender_before   = sender_account.amount
    receiver_before = receiver_account.amount

    sender_after   = sender_before - @remittance.sent_amount
    receiver_after = receiver_before + @remittance.received_amount

    sender_account.update!(amount: sender_after)
    receiver_account.update!(amount: receiver_after)

    @remittance.xtransactions.create!(
      xaccount: sender_account,
      currency: sender_account.currency,
      withdrawal_amount: @remittance.sent_amount,
      balance_before_transaction: sender_before,
      balance_after_transaction: sender_after
    )

    @remittance.xtransactions.create!(
      xaccount: receiver_account,
      currency: receiver_account.currency,
      deposit_amount: @remittance.received_amount,
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
    old_received_amount
  )
    # ----------------------------------------------
    # 1. Reverse old sender
    # ----------------------------------------------
    old_sender_before = old_sender_account.amount
    old_sender_after  = old_sender_before + old_sent_amount

    old_sender_account.update!(amount: old_sender_after)

    @remittance.xtransactions.create!(
      xaccount: old_sender_account,
      currency: old_sender_account.currency,
      deposit_amount: old_sent_amount,
      balance_before_transaction: old_sender_before,
      balance_after_transaction: old_sender_after
    )

    # ----------------------------------------------
    # 2. Reverse old receiver
    # ----------------------------------------------
    old_receiver_before = old_receiver_account.amount
    old_receiver_after  = old_receiver_before - old_received_amount

    old_receiver_account.update!(amount: old_receiver_after)

    @remittance.xtransactions.create!(
      xaccount: old_receiver_account,
      currency: old_receiver_account.currency,
      withdrawal_amount: old_received_amount,
      balance_before_transaction: old_receiver_before,
      balance_after_transaction: old_receiver_after
    )

    # ----------------------------------------------
    # 3. Apply new sender
    # ----------------------------------------------
    new_sender_account = @remittance.sender_account
    new_sender_before  = new_sender_account.amount
    new_sender_after   = new_sender_before - @remittance.sent_amount

    new_sender_account.update!(amount: new_sender_after)

    @remittance.xtransactions.create!(
      xaccount: new_sender_account,
      currency: new_sender_account.currency,
      withdrawal_amount: @remittance.sent_amount,
      balance_before_transaction: new_sender_before,
      balance_after_transaction: new_sender_after
    )

    # ----------------------------------------------
    # 4. Apply new receiver
    # ----------------------------------------------
    new_receiver_account = @remittance.receiver_account
    new_receiver_before  = new_receiver_account.amount
    new_receiver_after   = new_receiver_before + @remittance.received_amount

    new_receiver_account.update!(amount: new_receiver_after)

    @remittance.xtransactions.create!(
      xaccount: new_receiver_account,
      currency: new_receiver_account.currency,
      deposit_amount: @remittance.received_amount,
      balance_before_transaction: new_receiver_before,
      balance_after_transaction: new_receiver_after
    )
  end
end