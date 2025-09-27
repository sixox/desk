class CandidatesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_candidate, only: [:show, :edit, :update, :destroy]

  def index
    @candidates = Candidate
                    .includes(:candidate_profile, :candidate_evaluations)
                    .order(created_at: :desc)
  end

  def new
    @candidate = Candidate.new
  end

  def show
    # eager-load to avoid N+1
    @profile = @candidate.try(:candidate_profile)
    @evaluations = @candidate.respond_to?(:candidate_evaluations) ? @candidate.candidate_evaluations.to_a : []

    @hr_eval        = @evaluations.find { |e| e.department == "HR" }
    @ceo_eval       = @evaluations.find { |e| e.department == "CEO" }
    @dept_key, @dept_label =
      if @candidate.role.to_s.downcase == "accounting"
        ["Accounting", "Accounting"]
      else
        ["Other", (@candidate.role.presence || "Other").to_s.capitalize]
      end
    @dept_eval      = @evaluations.find { |e| e.department == @dept_key }
  end

  def create
    @candidate = Candidate.new(candidate_params)
    if @candidate.save
      redirect_to candidates_path, notice: "Candidate created successfully."
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @candidate.update(candidate_params)
      redirect_to candidates_path, notice: "Candidate updated successfully."
    else
      render :edit
    end
  end

  def destroy
    @candidate.destroy
    redirect_to candidates_path, notice: "Candidate deleted successfully."
  end


  def profile
    @candidate = Candidate.find(params[:id])
    @profile   = @candidate.candidate_profile

    unless @profile
      redirect_to candidates_path, alert: "فرمی برای این متقاضی ثبت نشده است." and return
    end
  end


  private

  def set_candidate
    @candidate = Candidate.find(params[:id])
  end

  def candidate_params
    params.require(:candidate).permit(:name, :phone, :role, :password, :password_confirmation)
  end
end
