class SpisController < ApplicationController
  before_action :authenticate_user!
  before_action :find_ballance

  def new
    @spi = @ballance.build_spi
  end

  def create
    @spi = @ballance.build_spi(spi_params)
    @spi.user = current_user
    @spi.supplier = @ballance.supplier
    @spi.product = @ballance.product
    if @spi.save
      redirect_to ballance_path(@ballance), notice: "PI created successfully."
    else
      render :new
    end
  end

  def edit
    @spi = Spi.find(params[:id])

  end

def update
  @spi = Spi.find(params[:id])
  respond_to do |format|
    if @spi.update(spi_params)
      format.turbo_stream { render turbo_stream: turbo_stream.replace("spi_item_#{@spi.id}", partial: 'spis/spi', locals: { spi: @spi, ballance: @spi.ballance }) }
    else
      # redirect_to root_path
      format.turbo_stream { render turbo_stream: turbo_stream.replace('remote_modal', partial: 'shared/turbo_modal', locals: { form_partial: 'spis/form', modal_title: 'Edit PI' })}
    end
  end
end

def destroy
    @spi = Spi.find(params[:id])

  respond_to do |format|
    @spi.destroy
    format.turbo_stream { render turbo_stream: turbo_stream.remove("spi_item_#{@spi.id}") }
  end
end

private

def find_ballance
  @ballance = Ballance.find(params[:ballance_id])
end

def spi_params
  params.require(:spi).permit(
    :number,
    :product,
    :validity,
    :user_id,
    :quantity,
    :unit_price,
    :payment_term,
    :bank_account,
    :packing_type,
    :packing_count,
    :supplier,
    :seller,
    :issue_date,
    :term,
    :ballance_id,
    :total_price,
    :document
  )
end


end
