class MessagesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_message, only: [:edit, :update, :show, :add_observer, :add_tag]
  before_action :set_user, only: [:index, :unread, :sent, :received, :observed, :add_tag]
  before_action :set_users, only: [:new, :edit]

  def show
    # Set the star to false for the sender if current_user is the sender
    if @message.sender == current_user
      @message.update(star: false) # Set star for the sender to false
    end

    # Set the star to false for the receiver if current_user is the receiver
    if @message.receiver == current_user
      @message.message_status.update(star: false) if @message.message_status.present? # Set star for the receiver to false
    end

    # Set the star to false for observers if current_user is an observer
    if @message.observers.include?(current_user)
      message_observer = @message.message_observers.find_by(observer: current_user)
      message_observer.update(star: false) if message_observer.present? # Set star for the observer to false
    end

    # Mark as read for the current user (sender, receiver, or observer)
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

  def add_tag
    tag = params[:tag].to_s.strip.titleize

    if tag.present?
      message_tag = @message.message_tags.find_or_initialize_by(user: @user)
      message_tag.tag = tag

      if message_tag.save
        flash[:notice] = "Tag '#{tag}' was successfully added to the message."
      else
        flash[:alert] = "Failed to add tag: #{message_tag.errors.full_messages.join(', ')}"
      end
    else
      flash[:alert] = "Tag cannot be blank."
    end

    redirect_to message_path(@message)
  end


  def new
    @message = Message.new
  end

 before_action :set_user
   def index
    @in_page = "index"

    # Base query for received, sent, and observed messages
    received_messages = @user.received_messages.select("messages.*, 'received' as message_type")
    sent_messages = @user.sent_messages.select("messages.*, 'sent' as message_type")
    observed_messages = @user.observed_messages.select("messages.*, 'observed' as message_type")

    # Combine queries using UNION
    combined_messages = Message.from("(#{received_messages.to_sql} UNION #{sent_messages.to_sql} UNION #{observed_messages.to_sql}) AS messages")

    # Filter messages by tag if a tag is selected
    if params[:tag].present?
      combined_messages = combined_messages.joins(:message_tags)
                                           .where(message_tags: { tag: params[:tag], user_id: @user.id })
    end

    # Apply Ransack to the combined messages
    @q = combined_messages.ransack(params[:q])
    @messages = @q.result.order(updated_at: :desc).page(params[:page]).per(12)

    # Fetch all tags for the current user for the dropdown
    @tags = MessageTag.where(user: @user).distinct.pluck(:tag)
  end

  def unread
    @in_page = "unread"
    received_messages = @user.received_messages
                     .includes(:sender, :observers, :message_status)
                     .where(message_statuses: { status: 'unread' })

    observed_messages = @user.observed_messages
                     .includes(:sender, :observers, :message_status)
                     .where(message_observers: { read: [false, nil] })

    @messages = (received_messages + observed_messages)
                .flatten
                .uniq
                .sort_by(&:updated_at)
                .reverse

    render 'index'
  end


  def sent
    @in_page = "sent"

    sent_messages = @user.sent_messages.includes(:sender, :observers, :message_status)

    # Apply Ransack to the sent messages
    @q = sent_messages.ransack(params[:q])
    @messages = @q.result.order(updated_at: :desc).page(params[:page]).per(12)

    render 'index'
  end

  def received
    @in_page = "received"

    received_messages = @user.received_messages.includes(:sender, :observers, :message_status)

    # Apply Ransack to the received messages
    @q = received_messages.ransack(params[:q])
    @messages = @q.result.order(updated_at: :desc).page(params[:page]).per(12)

    render 'index'
  end

  def observed
    @in_page = "observed"

    observed_messages = @user.observed_messages.includes(:sender, :observers, :message_status)

    # Apply Ransack to the observed messages
    @q = observed_messages.ransack(params[:q])
    @messages = @q.result.order(updated_at: :desc).page(params[:page]).per(12)

    render 'index'
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

def add_observer

  if request.get?
    # Filter @users to exclude sender, receiver, and existing observers
    set_users
    excluded_user_ids = [@message.sender_id, @message.receiver_id] + @message.observers.pluck(:id)
    @users = @users.where.not(id: excluded_user_ids)
  elsif request.post?
    observer_ids = params[:observer_ids].reject(&:blank?) # Change this line
    observer_ids.each do |observer_id|
      @message.message_observers.create(observer_id: observer_id)
    end
    redirect_to message_path(@message), notice: 'Observers were successfully added.'
  end
end



  private

  def set_user
    @user = current_user
  end

  def set_users
    @users = User.where.not(id: [2, 4, 25, 28, 30, 34])
  end

  def set_message
    @message = Message.find(params[:id])
  end

  

  def message_params
    params.require(:message).permit(:subject, :body, :receiver_id, :sender_id, :star, files: []).tap do |message_params|
      # Ensure the body is sanitized and any unnecessary leading/trailing spaces are trimmed
      message_params[:body] = message_params[:body].to_s.strip if message_params[:body].present?
    end
  end

end
