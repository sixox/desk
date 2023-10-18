class ScisController < ApplicationController
	before_action :authenticate_user!
	before_action :find_ballance


	def new
	  @sci = @ballance.scis.build
	end

	def create
	@sci = @ballance.scis.build(sci_params)
	@sci.user = current_user
	@sci.spi = @ballance.spi
	if @sci.save
      redirect_to ballance_path(@ballance), notice: "CI created successfully."
    else
      render :new
    end



	end

	def edit
		@sci = Sci.find(params[:id])
	end

	def update
  @sci = Sci.find(params[:id])
  respond_to do |format|
    if @sci.update(sci_params)
      format.turbo_stream { render turbo_stream: turbo_stream.replace("sci_item_#{@sci.id}", partial: 'scis/sci', locals: { sci: @sci, ballance: @sci.ballance }) }
    else
      # redirect_to root_path
      format.turbo_stream { render turbo_stream: turbo_stream.replace('remote_modal', partial: 'shared/turbo_modal', locals: { form_partial: 'scis/form', modal_title: 'Edit CI' })}
    end
  end
end

def destroy
    @sci = Sci.find(params[:id])

  respond_to do |format|
    @sci.destroy
    format.turbo_stream { render turbo_stream: turbo_stream.remove("sci_item_#{@sci.id}") }
  end
end

	private

def sci_params
  params.require(:sci).permit(
    :spi_id,
    :net_weight,
    :gross_weight,
    :total_price,
    :advance_payment,
    :balance_payment,
    :bank_account,
    :issue_date,
    :have_loading_report,
    :status,
    :user_id,
    :ballance_id,
    :document,
    :number
  )
end


	def find_ballance
		@ballance = Ballance.find(params[:ballance_id])
	end



end
