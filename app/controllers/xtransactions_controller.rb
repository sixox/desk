class XtransactionsController < ApplicationController
  before_action :authenticate_user!
  
  def index
    @xtransactions = Xtransaction
    .includes(:xaccount, :currency)
    .order(created_at: :desc)

    if params[:account_id].present?
      @xtransactions = @xtransactions.where(xaccount_id: params[:account_id])
    end
  end
end