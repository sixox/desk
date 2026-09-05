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

    if @remittance.save
      attach_documents
      redirect_to remittances_path,
                  notice: "Remittance created successfully."
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
    if @remittance.update(remittance_params)
      attach_documents
      redirect_to remittances_path,
                  notice: "Remittance updated successfully."
    else
      load_form_data
      render :edit, status: :unprocessable_entity
    end
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
      # :documents removed — handled manually so we append, not replace
    )
  end

  def attach_documents
    return if params[:remittance].blank?
    return if params[:remittance][:documents].blank?

    @remittance.documents.attach(params[:remittance][:documents])
  end
end