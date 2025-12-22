# app/controllers/manual_entries_controller.rb
class ManualEntriesController < ApplicationController
  before_action :authenticate_user!

  def new
    @manual_entry = ManualEntry.new
  end

  def create
    @manual_entry = ManualEntry.new(manual_entry_params)
    @manual_entry.user_id = current_user.id
    if @manual_entry.save
      flash[:notice] = "Manual entry recorded successfully."
      redirect_to member_path(current_user)  # redirect to an appropriate page (e.g., attendance overview)
    else
      flash[:alert] = @manual_entry.errors.full_messages.to_sentence
      render :new
    end
  end

  private

  def manual_entry_params
    params.require(:manual_entry).permit(:occurred_at, :is_entry, :description)
  end
end
