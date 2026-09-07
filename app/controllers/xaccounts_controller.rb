class XaccountsController < ApplicationController
  before_action :set_xaccount, only: [:show, :edit, :update, :destroy]

  def index
    @xaccounts = Xaccount
      .includes(:organization, :currency)
      .order(created_at: :desc)
  end

  def show; end

  def new
    @xaccount = Xaccount.new
    load_form_data
  end

  def create
    @xaccount = Xaccount.new(xaccount_params)

    Xaccount.transaction do
      @xaccount.save!

      if @xaccount.start_amount.present? && @xaccount.start_amount != 0
        @xaccount.xtransactions.create!(
          xaccount: @xaccount,
          currency: @xaccount.currency,
          deposit_amount: @xaccount.start_amount,
          balance_before_transaction: 0,
          balance_after_transaction: @xaccount.amount
        )
      end
    end

    redirect_to xaccounts_path, notice: "Account created successfully."
  rescue ActiveRecord::RecordInvalid
    load_form_data
    render :new, status: :unprocessable_entity
  end

  def edit
    load_form_data
  end

  def update
    old_amount = @xaccount.amount.to_i

    Xaccount.transaction do
      @xaccount.update!(xaccount_params)

      # saved_change_to_start_amount? is true ONLY when the DB value actually changed
      if @xaccount.saved_change_to_start_amount?
        old_start_amount = @xaccount.start_amount_before_last_save.to_i
        difference     = @xaccount.start_amount.to_i - old_start_amount

        xtransaction_attrs = {
          xaccount: @xaccount,
          currency: @xaccount.currency,
          balance_before_transaction: old_amount,
          balance_after_transaction: @xaccount.amount,
          transactionable_type: "First Issue",
          transactionable: @xaccount
        }

        if difference > 0
          xtransaction_attrs[:deposit_amount] = difference
        elsif difference < 0
          xtransaction_attrs[:withdrawal_amount] = -difference
        end

        @xaccount.xtransactions.create!(xtransaction_attrs) if difference != 0
      end
    end

    redirect_to xaccounts_path, notice: "Account updated successfully."
  rescue ActiveRecord::RecordInvalid
    load_form_data
    render :edit, status: :unprocessable_entity
  end

  def destroy
    if @xaccount.destroy
      redirect_to xaccounts_path, notice: "Account deleted successfully."
    else
      redirect_to xaccounts_path, alert: @xaccount.errors.full_messages.to_sentence
    end
  end

  private

  def set_xaccount
    @xaccount = Xaccount.find(params[:id])
  end

  def load_form_data
    @organizations = Organization.order(:name)
    @currencies = Currency.order(:name)
  end

  def xaccount_params
    params.require(:xaccount).permit(
      :number,
      :kind,
      :currency_id,
      :organization_id,
      :start_amount,
      :details_of_change_start_amount
    )
  end
end