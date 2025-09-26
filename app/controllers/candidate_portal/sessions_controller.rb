# app/controllers/candidate_portal/sessions_controller.rb
class CandidatePortal::SessionsController < ApplicationController
  layout "application"  # reuse your normal layout

  def new
  end

  def create
    cand = Candidate.find_by(phone: params[:phone].to_s.strip)
    if cand&.authenticate(params[:password].to_s)
      session[:portal_candidate_id] = cand.id
      redirect_to edit_candidate_portal_profile_path
    else
      flash.now[:alert] = "شماره یا رمز عبور نادرست است."
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    reset_portal!
    redirect_to candidate_portal_login_path, notice: "خروج انجام شد."
  end

  private

  def reset_portal!
    session.delete(:portal_candidate_id)
  end
end
