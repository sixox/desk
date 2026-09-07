class OrganizationsController < ApplicationController
  before_action :set_organization, only: [:edit, :update, :destroy]

  def index
    @organizations = Organization
      .includes(:xaccounts)
      .order(created_at: :desc)
  end

  def new
    @organization = Organization.new
    @organization.xaccounts.build
    load_form_data
  end

  def create
    @organization = Organization.new(organization_params)

    if @organization.save
      redirect_to organizations_path, notice: "Organization created."
    else
      load_form_data
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @organization.xaccounts.build if @organization.xaccounts.empty?
    load_form_data
  end

  def update
    if @organization.update(organization_params)
      redirect_to organizations_path, notice: "Organization updated."
    else
      load_form_data
      render :edit, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotDestroyed => e
    load_form_data
    flash.now[:alert] = "Cannot remove account because it has associated records."
    render :edit, status: :unprocessable_entity
  end

  def destroy
    if @organization.destroy
      redirect_to organizations_path, notice: "Organization deleted."
    else
      redirect_to organizations_path, alert: @organization.errors.full_messages.to_sentence
    end
  end

  private

  def set_organization
    @organization = Organization.find(params[:id])
  end

  def load_form_data
    @currencies = Currency.order(:name)
  end

  def organization_params
    params.require(:organization).permit(
      :name,
      :kind,
      xaccounts_attributes: [
        :id,
        :number,
        :kind,
        :currency_id,
        :_destroy
      ]
    )
  end
end