class BanksController < ApplicationController
  before_action :authenticate_user!
  before_action :set_bank, only: %i[show edit update destroy transactions]
  before_action :set_access_to_secret, only: %i[show]

  def index
    @banks = Bank.all
  end

  def show
    @deposits = @bank.deposits
    @all_transfers = @bank.withdrawn_transfers.or(@bank.deposited_transfers).order(created_at: :desc)
    @paid_payment_orders = @bank.payment_orders.joins(:receipt_attachment).where.not(active_storage_attachments: { id: nil })
    @waiting_payment_orders = @bank.payment_orders.where(status: 'wait for payment')
    @confirmed_swifts = @bank.swifts.where(confirmed: true)
    @unconfirmed_unrejected_swifts = @bank.swifts.where(confirmed: [nil, false], rejected: [nil, false])
    @unconfirmed_unrejected_swifts.each do |swift|
      if swift.currency == @bank.currency
        @sum_unconfirmed_unrejected_swifts = @sum_unconfirmed_unrejected_swifts.to_i + swift.amount
      else
        swift.currency == "dollar" ? a = swift.amount * 3.67 : a = swift.amount / 3.67
        @sum_unconfirmed_unrejected_swifts = @sum_unconfirmed_unrejected_swifts.to_i + a.to_i
      end
    end
  end

  def new
    @bank = Bank.new
  end

  def create
    @bank = Bank.new(bank_params)

    if @bank.save
      redirect_to @bank, notice: 'Bank was successfully created.'
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @bank.update(bank_params)
      redirect_to @bank, notice: 'Bank was successfully updated.'
    else
      render :edit
    end
  end

  def export
    csv_data = Transaction.to_csv
    send_data csv_data, filename: "transactions-#{Date.today}.csv", type: "text/csv"
  end

  def destroy
    @bank.destroy
    redirect_to banks_url, notice: 'Bank was successfully destroyed.'
  end

  def transactions
    # Fetch transactions for the bank, including associated data to prevent N+1 query problem
    transactions = @bank.transactions.includes(:transactionable)

    # Filter transactions by date range if provided
    if params[:start_date].present? && params[:end_date].present?
      start_date = Date.parse(params[:start_date])
      end_date = Date.parse(params[:end_date]).end_of_day
      transactions = transactions.where(created_at: start_date..end_date)
    end

    # Sort transactions to show the latest ones first
    transactions = transactions.order(created_at: :desc)

    # Paginate the transactions using Kaminari
    @transactions = transactions.page(params[:page]).per(30)  # Adjust 'per' to the number of transactions per page
  end

  def transaction
    @transactions = Transaction.all.includes(:transactionable).order(created_at: :desc).page(params[:page]).per(30)
  end




  private

  def set_access_to_secret
    if current_user.ceo? || current_user.cob? || current_user.admin? || (current_user.accounting? && current_user.is_manager )
      @access_to_secret = true
    end
  end

  def set_bank
    @bank = Bank.find(params[:id])
  end

  def bank_params
    params.require(:bank).permit(:name, :kind, :currency, :account_balance, :checked_balance)
  end
end
