class ExchangesController < ApplicationController
  before_action :set_exchange, only: [
    :edit,
    :update,
    :destroy,
    :toggle_pending,
    :remove_document
  ]

  def index
    @exchanges =
      Exchange
        .includes(
          :sell_currency,
          :buy_currency,
          seller_account: :organization,
          buyer_account: :organization
        )
        .order(created_at: :desc)
  end

  def new
    @exchange = Exchange.new
    load_form_data

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def create
    @exchange = Exchange.new(exchange_params)

    if @exchange.save
      update_transfers

      redirect_to exchanges_path,
                  notice: "Exchange created successfully."
    else
      load_form_data

      respond_to do |format|
        format.html do
          render :new, status: :unprocessable_entity
        end

        format.turbo_stream
      end
    end
  end

  def edit
    load_form_data
  end

  def update
    if @exchange.update(exchange_params)
      update_transfers

      redirect_to exchanges_path,
                  notice: "Exchange updated successfully."
    else
      load_form_data

      render :edit,
             status: :unprocessable_entity
    end
  end

  def destroy
    @exchange.destroy

    redirect_to exchanges_path,
                notice: "Exchange deleted successfully."
  end

  def toggle_pending
    if @exchange.pending?
      @exchange.unset_pending!
    else
      @exchange.set_pending!
    end

    redirect_to exchanges_path
  end

  def accounts
    organization = Organization.find(params[:organization_id])

    accounts = organization.xaccounts.includes(:currency)

    render json: accounts.map { |account|
      {
        id: account.id,
        number: account.number,
        kind: account.kind,
        currency_id: account.currency_id,
        currency_name: account.currency.name,
        organization_name: organization.name,
        organization_kind: organization.kind
      }
    }
  end

  def remove_document
    document = @exchange.documents.find(params[:document_id])

    document.purge

    redirect_to edit_exchange_path(@exchange),
                notice: "Attachment removed."
  end

  private

  def set_exchange
    @exchange = Exchange.find(params[:id])
  end

  def load_form_data
    @organizations = Organization.order(:name)
    @currencies = Currency.order(:name)

    @finished_transfers =
      Xtransfer
        .where.not(status: "finished")
        .includes(
          sender_account: [:organization, :currency],
          receiver_account: [:organization, :currency]
        )
        .order(created_at: :desc)

    @seller_accounts =
      if @exchange.seller_account.present?
        @exchange
          .seller_account
          .organization
          .xaccounts
          .includes(:currency)
      else
        Xaccount.none
      end

    @buyer_accounts =
      if @exchange.buyer_account.present?
        @exchange
          .buyer_account
          .organization
          .xaccounts
          .includes(:currency)
      else
        Xaccount.none
      end
  end

  def update_transfers
    transfer_ids =
      exchange_params[:xtransfer_ids]
        .reject(&:blank?)

    @exchange.xtransfer_ids = transfer_ids
  end

  def exchange_params
    params.require(:exchange).permit(
      :seller_account_id,
      :buyer_account_id,
      :sell_currency_id,
      :buy_currency_id,
      :exchange_rate,
      :sell_amount,
      :buy_amount,
      :wage,
      :kind,
      :pending,
      :documents,
      xtransfer_ids: []
    )
  end
end