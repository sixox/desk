class PisController < ApplicationController
  before_action :authenticate_user!
  before_action :find_project, only: %i[ new create edit update ]
  before_action :set_pi, only: [:update_temp, :destroy, :update_temp_form]



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

  def index
    @sort_by = params[:sort_by] || 'project_number_desc'
    @pis_with_project = Pi.with_project.custom_order(@sort_by)
    @pis_without_project = Pi.without_project
    @pis_with_project = @pis_with_project.page(params[:page]).per(25)

    
  end

  def new_temp
    @pi = Pi.new
  end

  def create_temp
    @pi = Pi.new(pi_params)
    @pi.user = current_user

    if @pi.save
      redirect_to @pi, notice: 'Pi was successfully created.'
    else
      render :new_temp
    end
  end

  def update_temp
    if @pi.update(pi_params)
      redirect_to @pi, notice: 'Pi was successfully updated.'
    else
      render :edit
    end
  end

  def update_temp_form
  end


  def assign_project
    @pi = Pi.find(params[:id])
    @projects = Project.left_outer_joins(:pi)
                       .where(pis: { id: nil })
  end

  def assign_project_form
    @pi = Pi.find(params[:id])
    @projects = Project.left_outer_joins(:pi)
                       .where(pis: { id: nil })
    if @pi.update(pi_params)
      puts "Debug: Project ID after update - #{@pi.project_id}" # Debugging line
      redirect_to project_path(@pi.project), notice: "PI created successfully."      
    else
      redirect_to pis_path, alert: 'Pi could not be add to project. Please try again.'
    end
  

  end



  def update
    @pi = Pi.find(params[:id])
    respond_to do |format|
      if @pi.update(pi_params)
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace("pi_item_#{@pi.id}", partial: 'pis/pi', locals: { pi: @pi, project: @pi.project }),
            turbo_stream.update('notices', partial: 'shared/notices', locals: { notice: 'PI was successfully updated.' })
          ]
        end
      else
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace('remote_modal', partial: 'shared/turbo_modal', locals: { form_partial: 'pis/form', modal_title: 'Edit PI' }),
            turbo_stream.update('notices', partial: 'shared/notices', locals: { alert: 'Error updating PI.' })
          ]
        end
      end
    end
  end


def create_document
    # Assuming the template_document is attached to a GeneratedDocument instance
    template_document = LetterHead.find(params[:generated_document][:template_id])
    model_object = Pi.find(params[:id]) # Or Ci.find(params[:id]) based on the form submission

    existing_document = model_object.generated_document
    existing_document.destroy if existing_document.present?

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

    new_document.file.attach(io: File.open(output_path), filename: "#{model_object.class.name.downcase}_#{model_object.number}.docx")

    
    if new_document.save
      if model_object.project.present?
        redirect_to project_path(model_object.project), notice: 'Document was successfully created.'
      else
        redirect_to pis_path, notice: 'Document was successfully created.'
      end
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
    # Now attempt to destroy the Pi record
  if @pi.destroy
    redirect_to pis_path, notice: 'Pi was successfully destroyed.'
  else
    redirect_to pis_path, alert: 'Pi could not be destroyed. Please try again.'
  end
end


private

def set_pi
  @pi = params[:id] ? Pi.find(params[:id]) : Pi.new
end

def find_project
  @project = Project.find(params[:project_id])
end

def pi_params
  params.require(:pi).permit(
    :number, :product, :validity, :quantity, :unit_price, :payment_term,
    :bank_account, :packing_type, :packing_count, :shipment_rate, :seller,
    :delivery_time, :issue_date, :pol, :pod, :customer_id, :user_id, :project_id, :currency, 
    :total_price, :tolerance, :incoterm, :account_id, :document
    )
end

  def document_params
    params.permit(:template_id)
  end

  def process_temp_save
    action = params[:pi][:action]
    if action == "create_temp" && @pi.save
      redirect_to pis_path, notice: 'Pi was successfully created.'
    elsif action == "update_temp" && @pi.update(pi_params)
      redirect_to pis_path, notice: 'Pi was successfully updated.'
    else
      render :new
    end
  end

end
