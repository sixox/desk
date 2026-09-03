class XpaymentsController < ApplicationController
  before_action :set_xpayment, only: [:edit, :update, :destroy]

  def index
    @xpayments =
    Xpayment
    .includes(
      :currency,
      sender_account: :organization,
      receiver_account: :organization
      )
    .order(created_at: :desc)
  end

  def new
    @xpayment = Xpayment.new
    load_form_data

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def create
    @xpayment = Xpayment.new(xpayment_params)

    if @xpayment.save
      redirect_to xpayments_path,
      notice: "Payment created successfully."
    else
      load_form_data

      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
        format.turbo_stream { render :new, status: :unprocessable_entity }
      end
    end
  end

  def edit
    load_form_data
  end

  def update
    if @xpayment.update(xpayment_params)
      redirect_to xpayments_path,
      notice: "Payment updated successfully."
    else
      load_form_data
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @xpayment.destroy

    redirect_to xpayments_path,
    notice: "Payment deleted successfully."
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

  private

  def set_xpayment
    @xpayment = Xpayment.find(params[:id])
  end

  def load_form_data
    @organizations = Organization.order(:name)
    @currencies = Currency.order(:name)

    @sender_accounts =
    if @xpayment.sender_account.present?
      @xpayment.sender_account.organization.xaccounts.includes(:currency)
    else
      Xaccount.none
    end

    @receiver_accounts =
    if @xpayment.receiver_account.present?
      @xpayment.receiver_account.organization.xaccounts.includes(:currency)
    else
      Xaccount.none
    end
  end

  def xpayment_params
    params.require(:xpayment).permit(
      :sender_account_id,
      :receiver_account_id,
      :sent_amount,
      :received_amount,
      :currency_id,
      :wage
      )
  end
end