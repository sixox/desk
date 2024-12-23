class MessagesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_message, only: [:edit, :update, :show]

  def show
    if @message.observers.include?(current_user)
      # Mark as read for observers
      message_observer = @message.message_observers.find_by(observer: current_user)
      message_observer.update(read: true) if message_observer.present?
    elsif @message.receiver == current_user
      # Mark as read for the receiver
      @message.message_status.update(status: "read") if @message.message_status.present?
    end
    # Instance variable for receiver and its status
    @receiver = @message.receiver
    @receiver_status = @message.message_status

    # Instance variable for observers and their read statuses
    @observers = @message.message_observers.includes(:observer)
    @acts = @message.acts
  end

  def new
    @message = Message.new
    @users = User.all # Fetch all users for receiver and observer selection
  end

  def index
    @user = current_user 
    # Define @messages with eager loading to prevent N+1 queries
    received_messages = @user.received_messages.includes(:sender, :observers, :message_status)
    sent_messages = @user.sent_messages.includes(:sender, :observers, :message_status)
    observed_messages = @user.observed_messages.includes(:sender, :observers, :message_status)

    @messages = (received_messages + sent_messages + observed_messages)
                .flatten
                .uniq
                .sort_by(&:created_at)
                .reverse


  end

  def create
    @message = Message.new(message_params)
    @message.sender = current_user
    if @message.save
      # Filter out observer IDs that are the same as sender or receiver
      observer_ids = params[:message][:observer_ids].reject do |observer_id|
        observer_id.blank? || observer_id.to_i == @message.sender_id || observer_id.to_i == @message.receiver_id
      end

      observer_ids.each do |observer_id|
        @message.message_observers.create(observer_id: observer_id)
      end

      redirect_to messages_path, notice: 'Message was successfully created.'
    else
      @users = User.all
      render :new, status: :unprocessable_entity
    end
  end


  def edit
    @users = User.all
  end

  def update
    if @message.update(message_params)
      # Update associated MessageObservers
      @message.message_observers.destroy_all
      observer_ids = params[:message][:observer_ids].reject(&:blank?)
      observer_ids.each do |observer_id|
        @message.message_observers.create(observer_id: observer_id)
      end

      redirect_to messages_path, notice: 'Message was successfully updated.'
    else
      @users = User.all
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_message
    @message = Message.find(params[:id])
  end

  def message_params
    params.require(:message).permit(:subject, :body, :receiver_id, :sender_id, files: [])
  end
end
