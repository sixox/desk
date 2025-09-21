class ExperiencesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_experience, only: %i[show edit update destroy]
  before_action :authorize_owner!, only: %i[edit update destroy]

  def index
    @experiences = Experience
                     .includes(:user)
                     .order(created_at: :desc)
                     .page(params[:page])    # 👈 paginate
                     .per(20)                # 👈 page size (tweak as you like)
  end

  def show
      if user_signed_in?
        @experience.experience_visits.find_or_create_by(user: current_user)
      end
  end

  def new
    @experience = Experience.new
  end

  def create
    @experience = Experience.new(experience_params)
    @experience.user = current_user
    if @experience.save
      redirect_to @experience, notice: "Experience created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @experience.update(experience_params)
      redirect_to @experience, notice: "Experience updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @experience.destroy
    redirect_to experiences_path, notice: "Experience deleted."
  end

  private

  def set_experience
    @experience = Experience.find(params[:id])
  end

  def authorize_owner!
    return if @experience.user_id == current_user.id
    redirect_to experiences_path, alert: "You are not allowed to modify this item."
  end

  def experience_params
    params.require(:experience).permit(:subject, :body, images: [], files: [])
  end
end
