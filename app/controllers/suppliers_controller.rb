class SuppliersController < ApplicationController
	before_action :authenticate_user!
	before_action :set_supplier, only: %i[ edit update destroy ]

	def index
		@suppliers = Supplier.all
	end

	def show
	end


	def new
		@supplier = current_user.suppliers.new
	end

	def edit
	end

	def create
		@supplier = current_user.suppliers.new(supplier_params)
		respond_to do |format|
			if @supplier.save
				format.turbo_stream { render turbo_stream: turbo_stream.prepend('supplier_items', partial: 'suppliers/supplier', locals: { supplier: @supplier }) }
			else
				format.turbo_stream { render turbo_stream: turbo_stream.replace('remote_modal', partial: 'shared/turbo_modal', locals: { form_partial: 'suppliers/form', modal_title: 'Add supplier' })}
			end
		end
	end

	def update
		respond_to do |format|
			if @supplier.update(supplier_params)
				format.turbo_stream { render turbo_stream: turbo_stream.replace("supplier_item_#{@supplier.id}", partial: 'suppliers/supplier', locals: { supplier: @supplier }) }
			else
				format.turbo_stream { render turbo_stream: turbo_stream.replace('remote_modal', partial: 'shared/turbo_modal', locals: { form_partial: 'suppliers/form', modal_title: 'Edit supplier ' })}
			end
		end
	end

	def destroy
		respond_to do |format|
			@supplier.destroy
			format.turbo_stream { render turbo_stream: turbo_stream.remove("supplier_item_#{@supplier.id}") }
		end
	end


	private

	def set_supplier
		@supplier = Supplier.find(params[:id])
	end

	def supplier_params
		params.require(:supplier).permit(:name)
	end

end