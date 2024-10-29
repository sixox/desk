class MeetingsController < ApplicationController
  before_action :set_meeting, only: %i[edit update show destroy]

  def new
    @meeting = Meeting.new
    @meeting.actions.build  # Initialize an empty action
  end

  def create
    @meeting = Meeting.new(meeting_params)
    @meeting.secretary = current_user

    if @meeting.save
      redirect_to @meeting, notice: 'Meeting was successfully created.'
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @meeting.update(meeting_params)
      redirect_to @meeting, notice: 'Meeting was successfully updated.'
    else
      render :edit
    end
  end

  private

  def set_meeting
    @meeting = Meeting.find(params[:id])
  end

  def meeting_params
    params.require(:meeting).permit(:title, :date, :guests, :details, :is_secret, participant_ids: [], actions_attributes: [:id, :description, :deadline, :user_id, :_destroy])
  end
end
