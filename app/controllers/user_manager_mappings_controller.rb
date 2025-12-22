class UserManagerMappingsController < ApplicationController
  before_action :authenticate_user!

  def index
    @users = User.includes(:user_manager_mapping).order(:id)
    @managers = User.order(:id)
  end

  def update
    user = User.find(params[:user_id])
    manager_id = params[:manager_id].presence || user.id

    mapping = UserManagerMapping.find_or_initialize_by(user_id: user.id)
    mapping.manager_id = manager_id
    mapping.save!

    redirect_to user_manager_mappings_path, notice: "Manager mapping updated."
  end
end
