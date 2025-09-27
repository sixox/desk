# app/controllers/candidate_portal/profile_controller.rb
class CandidatePortal::ProfileController < ApplicationController
  layout "application"
  before_action :require_portal_candidate!
  before_action :load_profile

  def show; end
  def edit; end

  def update
    incoming = params.fetch(:profile, {}).fetch(:data, {}).to_unsafe_h
    @profile.data = (@profile.data || {}).deep_merge(incoming)

    if @profile.save
      redirect_to edit_candidate_portal_profile_path, notice: "اطلاعات با موفقیت ذخیره شد.", status: :see_other
    else
      flash.now[:alert] = "ذخیره با خطا مواجه شد."
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def current_portal_candidate
    @current_portal_candidate ||= Candidate.find_by(id: session[:portal_candidate_id])
  end

  def require_portal_candidate!
    redirect_to candidate_portal_login_path, alert: "ابتدا وارد شوید." unless current_portal_candidate
  end

  def load_profile
    @candidate = current_portal_candidate
    @profile   = @candidate.candidate_profile || @candidate.build_candidate_profile(data: {})
  end
end
