class CisController < ApplicationController
	before_action :authenticate_user!
  before_action :find_project, only: %i[ new create edit update ]



	def new
	  @ci = @project.cis.build
	end

	def create
	@ci = @project.cis.build(ci_params)
	@ci.user = current_user
	@ci.pi = @project.pi
	if @ci.save
      redirect_to project_path(@project), notice: "CI created successfully."
    else
      render :new
    end
	end

	def index
		  # @cis = Ci.includes(:pi).all
	  @sort_by = params[:sort_by] || 'project_number_desc'
	  @cis = sort_cis(Ci.includes(pi: :project), @sort_by)
    @cis = @cis.page(params[:page]).per(20)

	end

	def create_document
	    # Assuming the template_document is attached to a GeneratedDocument instance
	    template_document = LetterHead.find(params[:generated_document][:template_id])
	    model_object = Ci.find(params[:id]) 

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
	    new_document.ci_id = params[:id]

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
	  @ci = Ci.find(params[:id])

	end

	def edit
		@ci = Ci.find(params[:id])
	end

	
	def update
	  @ci = Ci.find(params[:id])
	  respond_to do |format|
	    if @ci.update(ci_params)
	      format.turbo_stream do
	        render turbo_stream: [
	          turbo_stream.replace("ci_item_#{@ci.id}", partial: 'cis/ci', locals: { ci: @ci, project: @ci.project }),
	          turbo_stream.update('notices', partial: 'shared/notices', locals: { notice: 'CI was successfully updated.' })
	        ]
	      end
	    else
	      format.turbo_stream do
	        render turbo_stream: [
	          turbo_stream.replace('remote_modal', partial: 'shared/turbo_modal', locals: { form_partial: 'cis/form', modal_title: 'Edit CI' }),
	          turbo_stream.update('notices', partial: 'shared/notices', locals: { alert: 'Error updating CI.' })
	        ]
	      end
	    end
	  end
	end


def destroy
    @ci = Ci.find(params[:id])

  respond_to do |format|
    @ci.destroy
    format.turbo_stream { render turbo_stream: turbo_stream.remove("ci_item_#{@ci.id}") }
  end
end

	private

	def ci_params
		params.require(:ci).permit(:net_weight, :gross_weight, :total_price, 
			:advance_payment, :balance_payment, :bank_account, :issue_date, 
			:project_id, :user_id, :document, :number, :validity, :account_id
			)
	end

	def find_project
		@project = Project.find(params[:project_id])
	end

	def sort_cis(query, sort_by)
	  case sort_by
	  when 'ci_number'
	    query.order('number DESC')
	  when 'pi_number'
	    query.order('pis.number DESC')
	  when 'project_number_desc'
	    query.order('projects.number DESC')
	  when 'issue_date'
	    query.order('issue_date DESC')
	  else
	    query
	  end
	end



end
