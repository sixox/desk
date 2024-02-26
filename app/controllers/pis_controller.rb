class PisController < ApplicationController
  before_action :authenticate_user!
  before_action :find_project, only: %i[ new create edit update destroy ]


  def new
    @pi = @project.build_pi
  end

  def create
    @pi = @project.build_pi(pi_params)
    @pi.user = current_user
    if @pi.save
      redirect_to project_path(@project), notice: "PI created successfully."
    else
      render :new
    end
  end

  def edit
    @pi = Pi.find(params[:id])

  end

def update
  @pi = Pi.find(params[:id])
  respond_to do |format|
    if @pi.update(pi_params)
      format.turbo_stream { render turbo_stream: turbo_stream.replace("pi_item_#{@pi.id}", partial: 'pis/pi', locals: { pi: @pi, project: @pi.project }) }
    else
      # redirect_to root_path
      format.turbo_stream { render turbo_stream: turbo_stream.replace('remote_modal', partial: 'shared/turbo_modal', locals: { form_partial: 'pis/form', modal_title: 'Edit PI' })}
    end
  end
end

def create_document
    # Assuming the template_document is attached to a GeneratedDocument instance
    template_document = LetterHead.find(params[:generated_document][:template_id])
    model_object = Pi.find(params[:id]) # Or Ci.find(params[:id]) based on the form submission

    output_path = Rails.root.join('tmp', "#{SecureRandom.hex}.docx")
    template_document = LetterHead.find(params[:generated_document][:template_id])

    # Assuming the file is stored with Active Storage and you need to process it
    template_document.file.blob.open do |tempfile|
      # Pass the tempfile path to your DocxGenerator
      DocxGenerator.generate_from_template(tempfile.path, model_object, output_path)
    end

    # Create a new GeneratedDocument instance for the newly created document
    new_document = GeneratedDocument.new(user: current_user)
    new_document.pi_id = params[:id]

    new_document.file.attach(io: File.open(output_path), filename: "#{model_object.class.name.downcase}_document_#{model_object.number}_p#{model_object.project.number}.docx")

    
    if new_document.save
      redirect_to root_path, notice: 'Document was successfully created.'
    else
      render :new, alert: 'There was an error creating the document.'
    end
  ensure
    # Ensure temporary file is deleted after processing
    File.delete(output_path) if output_path && File.exist?(output_path)
end

def create_document_form
  @pi = Pi.find(params[:id])

end



def destroy
    @pi = Pi.find(params[:id])

  respond_to do |format|
    @pi.destroy
    format.turbo_stream { render turbo_stream: turbo_stream.remove("vacation_item_#{@pi.id}") }
  end
end

private

def find_project
  @project = Project.find(params[:project_id])
end

def pi_params
  params.require(:pi).permit(
    :number, :product, :validity, :quantity, :unit_price, :payment_term,
    :bank_account, :packing_type, :packing_count, :shipment_rate, :seller,
    :delivery_time, :issue_date, :pol, :pod, :customer_id, :user_id, :project_id, :currency, 
    :total_price, :tolerance, :document
    )
end

  def document_params
    params.permit(:template_id)
  end

end
