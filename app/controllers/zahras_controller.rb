class ZahrasController < ApplicationController
  before_action :set_zahra, only: %i[ show edit update destroy ]

  # GET /zahras or /zahras.json
  def index
    @zahras = Zahra.all
    @mohsen = "mohsen is here"
  end

  # GET /zahras/1 or /zahras/1.json
  def show
  end

  # GET /zahras/new
  def new
    @zahra = Zahra.new
  end

  # GET /zahras/1/edit
  def edit
  end

  # POST /zahras or /zahras.json
  def create
    @zahra = Zahra.new(zahra_params)

    respond_to do |format|
      if @zahra.save
        format.html { redirect_to zahra_url(@zahra), notice: "Zahra was successfully created." }
        format.json { render :show, status: :created, location: @zahra }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @zahra.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /zahras/1 or /zahras/1.json
  def update
    respond_to do |format|
      if @zahra.update(zahra_params)
        format.html { redirect_to zahra_url(@zahra), notice: "Zahra was successfully updated." }
        format.json { render :show, status: :ok, location: @zahra }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @zahra.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /zahras/1 or /zahras/1.json
  def destroy
    @zahra.destroy

    respond_to do |format|
      format.html { redirect_to zahras_url, notice: "Zahra was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_zahra
      @zahra = Zahra.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def zahra_params
      params.require(:zahra).permit(:name, :family, :phone)
    end
end
