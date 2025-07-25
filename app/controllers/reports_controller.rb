class ReportsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_report, only: [:show, :edit, :update, :destroy]

  # GET /reports
  def index
    if current_user.ceo? || current_user.admin? || current_user.cob? || current_user.id == 18
      # Show all reports for privileged roles
      @reports = Report.all.order(created_at: :desc)
    elsif current_user.accounting?
      # Include reports from both accounting and procurement roles
      @reports = Report.by_user_role([current_user.role, 'procurement']).order(created_at: :desc)
    else
      # Default behavior for other roles
      @reports = Report.by_user_role(current_user.role).order(created_at: :desc)
    end

    # Paginate the results
    @reports = @reports.page(params[:page]).per(10)
  end


  # GET /reports/1
  def show
  end

  # GET /reports/new
  def new
    @report = Report.new
  end

  # POST /reports
  def create
    @report = Report.new(report_params)
    @report.user = current_user

    if @report.save
      redirect_to @report, notice: 'Report was successfully created.'
    else
      render :new
    end
  end

  # GET /reports/1/edit
  def edit
  end

  # PATCH/PUT /reports/1
  def update
    if @report.update(report_params)
      redirect_to @report, notice: 'Report was successfully updated.'
    else
      render :edit
    end
  end

  # DELETE /reports/1
  def destroy
    @report.destroy
    redirect_to reports_url, notice: 'Report was successfully destroyed.'
  end

  private
    # Use callbacks to share common setup or constraints between actions
    def set_report
      @report = Report.find(params[:id])
    end

    # Only allow a list of trusted parameters through
    def report_params
      params.require(:report).permit(:subject, :details, :user_id, :invest, documents: [])
    end
end
