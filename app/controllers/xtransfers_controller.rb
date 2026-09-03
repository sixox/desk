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

    if @xtransfer.save
      attach_documents
      redirect_to xtransfers_path, notice: "Transfer created."
    else
      load_form_data
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    load_form_data
  end

  def update
    if @xtransfer.update(xtransfer_params)
      attach_documents
      redirect_to xtransfers_path, notice: "Transfer updated."
    else
      load_form_data
      render :edit, status: :unprocessable_entity
    end
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

  def set_xtransfer
    @xtransfer = Xtransfer.find(params[:id])
  end

  def load_form_data
    @organizations = Organization.order(:name)
    @currencies = Currency.order(:name)

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
        @xtransfer.sender_account.organization.xaccounts.includes(:currency)
      else
        Xaccount.none
      end

    @receiver_accounts =
      if @xtransfer.receiver_account.present?
        @xtransfer.receiver_account.organization.xaccounts.includes(:currency)
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
      :sender_currency_id,
      :receiver_currency_id,
      exchange_ids: []
      # documents removed — handled manually so we append, not replace
    )
  end

  def attach_documents
    return if params[:xtransfer].blank?
    return if params[:xtransfer][:documents].blank?

    @xtransfer.documents.attach(params[:xtransfer][:documents])
  end
end