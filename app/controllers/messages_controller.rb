class MessagesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_message, only: [:edit, :update, :show]
  before_action :set_user, only: [:index, :unread, :sent, :received, :observed]

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
    @in_page = "index"

    received_messages = @user.received_messages.select("messages.*, 'received' as message_type")
    sent_messages = @user.sent_messages.select("messages.*, 'sent' as message_type")
    observed_messages = @user.observed_messages.select("messages.*, 'observed' as message_type")

    # Use UNION to combine the queries
    @messages = Message.from("(#{received_messages.to_sql} UNION #{sent_messages.to_sql} UNION #{observed_messages.to_sql}) AS messages")
                       .order(created_at: :desc)
                       .page(params[:page])
                       .per(6)
  end


def unread
  @in_page = "unread"

  received_messages = @user.received_messages
                           .joins(:message_status)
                           .includes(:sender, :observers)
                           .where(message_statuses: { status: 'unread' })
                           .select("messages.id AS id, messages.sender_id AS sender_id, messages.receiver_id AS receiver_id, messages.subject AS subject, messages.body AS body, messages.created_at AS created_at, messages.updated_at AS updated_at, 'received' AS message_type")

  observed_messages = @user.observed_messages
                           .joins(:message_observers)
                           .includes(:sender, :observers)
                           .where(message_observers: { read: [false, nil] })
                           .select("messages.id AS id, messages.sender_id AS sender_id, messages.receiver_id AS receiver_id, messages.subject AS subject, messages.body AS body, messages.created_at AS created_at, messages.updated_at AS updated_at, 'observed' AS message_type")

  # Combine queries with UNION
  union_query = "(#{received_messages.to_sql} UNION ALL #{observed_messages.to_sql}) AS messages"
  @messages = Message.from(union_query)
                     .order(created_at: :desc)
                     .page(params[:page])
                     .per(6)

  render 'index'
end




  def sent
    @in_page = "sent"
    @messages = @user.sent_messages
                     .includes(:sender, :observers, :message_status)
                     .order(created_at: :desc)
                     .page(params[:page])
                     .per(6)

    render 'index'
  end


  def received
    @in_page = "received"
    @messages = @user.received_messages
                     .includes(:sender, :observers, :message_status)
                     .order(created_at: :desc)
                     .page(params[:page])
                     .per(6)

    render 'index'
  end


  def observed
    @in_page = "observed"
    @messages = @user.observed_messages
                     .includes(:sender, :observers, :message_status)
                     .order(created_at: :desc)
                     .page(params[:page])
                     .per(6)

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

  def set_user
    @user = current_user
  end

  def set_message
    @message = Message.find(params[:id])
  end

  def message_params
    params.require(:message).permit(:subject, :body, :receiver_id, :sender_id, files: [])
  end
end
