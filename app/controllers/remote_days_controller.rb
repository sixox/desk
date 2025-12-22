class RemoteDaysController < ApplicationController
  before_action :authenticate_user!
  before_action :set_remote_day, only: %i[edit update destroy]

  def index
    @remote_days = current_user.remote_days.order(date: :desc)
  end

  def new
    @remote_day = current_user.remote_days.new
    respond_to do |format|
      format.turbo_stream
      format.html
    end
  end

  def edit
    respond_to do |format|
      format.turbo_stream
      format.html
    end
  end

  def create
    @remote_day = current_user.remote_days.new(remote_day_params)

    if @remote_day.save
      redirect_to member_path(current_user), notice: 'Remote day was successfully created.'
    else
      # اگر create از داخل modal (turbo_stream) زده شد، همون modal رو با errors دوباره رندر کن
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            'remote_modal',
            partial: 'shared/turbo_modal',
            locals: { form_partial: 'remote_days/form', modal_title: 'Create Remote Day' }
          )
        end

        # اگر بدون turbo بود (صفحه‌ی html)، همون new رو نشون بده
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  def update
    if @remote_day.update(remote_day_params)
      redirect_to member_path(current_user), notice: 'Remote day was successfully updated.'
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            'remote_modal',
            partial: 'shared/turbo_modal',
            locals: { form_partial: 'remote_days/form', modal_title: 'Edit Remote Day' }
          )
        end

        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @remote_day.destroy
    redirect_to remote_days_path, notice: 'Remote day was successfully deleted.'
  end

  private

  def set_remote_day
    @remote_day = current_user.remote_days.find(params[:id])
  end

  def remote_day_params
    params.require(:remote_day).permit(:date, :confirmed, :text)
  end
end
