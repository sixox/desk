class DocumentsController < ApplicationController
	before_action :authenticate_user!
	
  def index
    @documents = Document.all
  end

  def show
    @document = Document.find(params[:id])
  end

  def new
    @document = Document.new
  end

  def create
    @document = Document.new(document_params)
    if @document.save
      redirect_to @document, notice: 'Document was successfully created.'
    else
      render :new
    end
  end

  private

  def document_params
    params.require(:document).permit(:name, :description, :title, documents: [])
  end

end
