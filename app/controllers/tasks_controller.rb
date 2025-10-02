# app/controllers/tasks_controller.rb
class TasksController < ApplicationController
  before_action :authenticate_user!

  def index
    scope = LeadTask
              .includes(:lead, :assigned_to)
              .where(status: :open) # only open tasks

    # Show mine by default; allow switching
    @assignee_id = params[:assignee_id].presence || current_user.id
    scope = scope.where(assigned_to_id: @assignee_id)

    today = Date.current
    @overdue  = scope.where("due_on IS NOT NULL AND due_on <  ?", today).order(:due_on, :created_at)
    @today    = scope.where(due_on: today).order(:created_at)
    @upcoming = scope.where("due_on > ?", today).order(:due_on, :created_at)
    @nodate   = scope.where(due_on: nil).order(:created_at)

    # For filter dropdown
    @users = User.order(:name)

    # Top counters
    @counts = {
      overdue:  @overdue.count,
      today:    @today.count,
      upcoming: @upcoming.count,
      nodate:   @nodate.count
    }
  end
end
