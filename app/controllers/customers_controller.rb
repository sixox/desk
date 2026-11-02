class CustomersController < ApplicationController
  before_action :authenticate_user!
before_action :set_customer, only: %i[show edit update destroy]
before_action :authorize_customer_access!, only: %i[index show]
before_action :authorize_customer_management!, only: %i[new create edit update destroy]

  
  def index
    customers = Customer.includes(
      :user,
      pis: [
        :project,
        { cis: :project }
      ]
    )

    search = params[:q].to_s.strip

    if search.present?
      term = "%#{Customer.sanitize_sql_like(search.downcase)}%"

      customers = customers.where(
        "LOWER(customers.name) LIKE :term OR " \
        "LOWER(customers.nickname) LIKE :term OR " \
        "LOWER(customers.company) LIKE :term",
        term: term
      )
    end

    customers =
      if params[:sort] == "recent"
        customers.order(updated_at: :desc)
      else
        customers.order(:nickname)
      end

    @customers = customers.to_a
    @customer_count = @customers.size
  end


  def show
    @overview = Customer360::Overview.new(@customer)
  end

  def new
    @customer = current_user.customers.new
  end

  def edit
  end

  
  def create
    @customer = current_user.customers.new(customer_params)

    respond_to do |format|
      if @customer.save

        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.prepend(
              "customer_items",
              partial: "customers/customer",
              locals: { customer: @customer }
            ),
            turbo_stream.update(
              "notices",
              partial: "shared/notices",
              locals: { notice: "Customer created successfully." }
            ),
            turbo_stream.update("remote_modal", "")
          ]
        end

        format.html do
          redirect_to customers_path, notice: "Customer created successfully."
        end

      else

        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace(
              "remote_modal",
              partial: "shared/turbo_modal",
              locals: {
                modal_title: "New Customer",
                modal_subtitle: "Correct the highlighted fields.",
                modal_icon: "fa-user-plus",
                modal_size: "modal-lg",
                form_partial: "customers/form",
                form_locals: {
                  customer: @customer,
                  in_modal: true
                }
              }
            ),
            turbo_stream.update(
              "notices",
              partial: "shared/notices",
              locals: { alert: "Please correct the customer information." }
            )
          ], status: :unprocessable_entity
        end

        format.html do
          render :new, status: :unprocessable_entity
        end

      end
    end
  end




  def update
    respond_to do |format|
      if @customer.update(customer_params)

        format.turbo_stream do
          render turbo_stream: [
            # Refresh the customer row when editing from the index.
            turbo_stream.replace(
              "customer_item_#{@customer.id}",
              partial: "customers/customer",
              locals: { customer: @customer }
            ),

            # Refresh Customer 360 header when editing from its show page.
            turbo_stream.update(
              "customer-show-title",
              @customer.name.presence || @customer.nickname.titleize
            ),

            turbo_stream.update(
              "customer-show-subtitle",
              "#{@customer.company.presence || 'Individual customer'} · #{@customer.nickname}"
            ),

            # Show success message.
            turbo_stream.update(
              "notices",
              partial: "shared/notices",
              locals: {
                notice: "Customer updated successfully."
              }
            ),

            # Remove modal contents. The bs-modal Stimulus controller
            # hides the Bootstrap modal when its element disconnects.
            turbo_stream.update("remote_modal", "")
          ]
        end

        format.html do
          redirect_to customer_path(@customer),
                      notice: "Customer updated successfully."
        end

      else

        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace(
              "remote_modal",
              partial: "shared/turbo_modal",
              locals: {
                modal_title: "Edit Customer",
                modal_subtitle: "Correct the highlighted information.",
                modal_icon: "fa-user-pen",
                modal_size: "modal-lg",
                form_partial: "customers/form",
                form_locals: {
                  customer: @customer,
                  in_modal: true
                }
              }
            ),

            turbo_stream.update(
              "notices",
              partial: "shared/notices",
              locals: {
                alert: "Please correct the customer information."
              }
            )
          ], status: :unprocessable_entity
        end

        format.html do
          render :edit, status: :unprocessable_entity
        end

      end
    end
  end



  def destroy
    respond_to do |format|
      @customer.destroy
      format.turbo_stream { render turbo_stream: turbo_stream.remove("customer_item_#{@customer.id}") }
    end
  end

  private

  def set_customer
    @customer = Customer.find(params[:id])
  end

  def customer_params
    params.require(:customer).permit(:name, :nickname, :company)
  end

  def total_invoices_dirham(customer)
    dollar_to_dirham = 3.67
    customer.sum_of_cis_without_swift[:dirham].to_i + (customer.sum_of_cis_without_swift[:dollar].to_i * dollar_to_dirham)
  end

  
  def authorize_customer_access!
    return if current_user.is_manager || current_user.sales?

    redirect_to root_path,
                alert: "You are not authorized to access customer information."
  end

  def authorize_customer_management!
    return if current_user.sales?

    redirect_to customers_path,
                alert: "You are not authorized to manage customers."
  end


end
