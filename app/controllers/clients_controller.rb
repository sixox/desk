class ClientsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_client, only: [:show, :edit, :update, :destroy, :change_status]

  def index
    @clients = current_user.clients
  end

  def show
  end

  def new
    @client = current_user.clients.build
  end

  def create
    @client = current_user.clients.build(client_params)
    @client.status = "New"

    if @client.save
      redirect_to @client, notice: 'Client was successfully created.'
    else
      render :new
    end
  end

  def edit
  end

  def change_status
  end

  def update
    if @client.update(client_params)
      redirect_to @client, notice: 'Client was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @client.destroy
    redirect_to clients_url, notice: 'Client was successfully destroyed.'
  end

  private

  def set_client
    @client = current_user.clients.find(params[:id])
  end

  def client_params
    params.require(:client).permit(:name, :company, :email, :phone, :received_from, :preferred_connection, :product, :country, :port, :packing, :details, :status, :update_status_at, :quantity, :follower)
  end
end
