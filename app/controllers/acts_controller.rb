class ActsController < ApplicationController
  before_action :set_message, only: :create
  before_action :authenticate_user!

  def create
    @act = @message.acts.new(act_params)
    @act.user = current_user

    if @act.save
      redirect_to message_path(@message), notice: 'Your action was successfully recorded.'
    else
      redirect_to message_path(@message), alert: 'Failed to save your action. Please try again.'
    end
  end

  private

  def set_message
    @message = Message.find(params[:act][:message_id])
  end

  def act_params
    params.require(:act).permit(:action_type, :action_details, :message_id)
  end
end
