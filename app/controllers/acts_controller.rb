class ActsController < ApplicationController
  before_action :set_message, only: :create
  before_action :authenticate_user!

  def create
    ActiveRecord::Base.transaction do
      # Build the new act associated with the message
      @act = @message.acts.new(act_params)
      @act.user = current_user

      # Save the act and star the message
      if @act.save && @message.star_message!(current_user)
        redirect_to message_path(@message), notice: 'Your action was successfully recorded and the message was starred.'
      else
        raise ActiveRecord::Rollback
      end
    end

  rescue => e
    # Log the error and provide feedback
    Rails.logger.error("Failed to create act or star the message: #{e.message}")
    redirect_to message_path(@message), alert: 'Failed to save your action or star the message. Please try again.'
  end


  private

  def set_message
    @message = Message.find(params[:act][:message_id])
  end

  def act_params
    params.require(:act).permit(:action_type, :action_details, :message_id)
  end
end
