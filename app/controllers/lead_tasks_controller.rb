# app/controllers/lead_tasks_controller.rb
class LeadTasksController < ApplicationController
  before_action :authenticate_user!
  before_action :set_lead
  before_action :set_task, only: [:update, :destroy, :toggle_done]

  def create
    @task = @lead.lead_tasks.new(task_params)
    @task.assigned_to ||= current_user
    if @task.save
      redirect_to lead_path(@lead), notice: "Task added."
    else
      redirect_to lead_path(@lead), alert: @task.errors.full_messages.to_sentence
    end
  end

  def update
    if @task.update(task_params)
      redirect_to lead_path(@lead), notice: "Task updated."
    else
      redirect_to lead_path(@lead), alert: @task.errors.full_messages.to_sentence
    end
  end

  def toggle_done
    @task.status = @task.open? ? :done : :open
    @task.save!
    redirect_to lead_path(@lead), notice: "Task #{@task.open? ? 'reopened' : 'completed'}."
  end



  def destroy
    @task.destroy
    redirect_to lead_path(@lead), notice: "Task deleted."
  end

  private

  def set_lead
    @lead = Lead.find(params[:lead_id])
  end

  def set_task
    @task = @lead.lead_tasks.find(params[:id])
  end

  def task_params
    params.require(:lead_task).permit(:title, :due_on, :notes, :assigned_to_id)
  end
end
