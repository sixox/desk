class RialReceiptsController < ApplicationController
  before_action :set_payment_order, only: [:new, :create, :edit, :update, :destroy, :show]
  before_action :set_rial_receipt, only: [:show, :edit, :update, :destroy]

  def new
    @rial_receipt = @payment_order.build_rial_receipt
  end

  def create
    @rial_receipt = @payment_order.build_rial_receipt(rial_receipt_params)

    # Default values from PaymentOrder if fields are left blank
    @rial_receipt.details ||= @payment_order.details
    @rial_receipt.receiver ||= @payment_order.to
    @rial_receipt.account_number ||= @payment_order.receiver_account
    @rial_receipt.check_bank ||= @payment_order.bank&.name

    if @rial_receipt.save
      redirect_to payment_order_path(@payment_order), notice: 'Rial Receipt was successfully created.'
    else
      render :new
    end
  end

  def show
    @manager = User.managers_for_role(@payment_order.user.role).first

  end

  def edit
  end

  def update
    if @rial_receipt.update(rial_receipt_params)
      redirect_to payment_order_path(@payment_order), notice: 'Rial Receipt was successfully modified.'
    else
      render :edit
    end
  end

  def destroy
    @rial_receipt.destroy
    redirect_to payment_order_path(@rial_receipt.payment_order), notice: 'Rial Receipt was successfully deleted.'
  end

  private

  def set_payment_order
    @payment_order = PaymentOrder.find(params[:payment_order_id])
  end

  def set_rial_receipt
    @rial_receipt = RialReceipt.find(params[:id])
  end

  def rial_receipt_params
    params.require(:rial_receipt).permit(
      :in_words, :details, :receiver, :account_number,
      :check_number, :check_bank, :check_date, :check_account,
      :from_source, :payment_date, :explain
    )
  end
end
