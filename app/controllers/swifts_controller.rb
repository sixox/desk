require "bigdecimal"
require "bigdecimal/util"

class SwiftsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_ci_or_project, only: %i[new create]
  before_action :set_swift, only: %i[confirm reject edit_amount_before_confirm edit update destroy toggle_announce]
  before_action :require_swift_editor, only: %i[edit update destroy]
  before_action :require_swift_accounting, only: %i[confirm reject edit_amount_before_confirm toggle_announce]

  def new
    @swift = build_swift
    @banks = Bank.all
  end

  def create
    @swift = build_swift(swift_params)
    @banks = Bank.all
    if @swift.save
      redirect_to swift_destination, notice: 'Swift created successfully.', status: :see_other
    else
      render :new, formats: [:turbo_stream], status: :unprocessable_entity
    end
  end

  def edit
    prepare_edit
  end

  def update
    attrs = swift_params
    attrs.delete(:documents) if attrs.key?(:documents) && Array(attrs[:documents]).all?(&:blank?)
    if @swift.car_project_id.present? || @swift.ci_id.present?
      attrs.delete(:project_id)
    end
    @swift.with_lock do
      return head :forbidden unless @swift.editable_by?(current_user)
      @swift.update!(attrs)
    end
    redirect_to swift_destination, notice: 'Swift was successfully updated.', status: :see_other
  rescue ActiveRecord::RecordInvalid
    prepare_edit
    render :edit, formats: [:turbo_stream], status: :unprocessable_entity
  end

  def edit_amount_before_confirm
    @banks = Bank.all
  end

  def index
    @in_page = 'index'
    @q = Swift.visible_to(current_user).with_bank_and_ci.ransack(params[:q])
    @swifts = @q.result.order(created_at: :desc).page(params[:page]).per(30)
  end

  def unconfirmed
    @in_page = 'unconfirmed'
    @q = Swift.visible_to(current_user).with_bank_and_ci.where(confirmed: [false, nil], rejected: [false, nil]).ransack(params[:q])
    @swifts = @q.result.order(created_at: :desc).page(params[:page]).per(30)
    render :index
  end

  def confirm
    attrs = params.require(:swift).permit(:bank_id, :deposited_amount)
    amount = BigDecimal(attrs[:deposited_amount].to_s, exception: false)
    unless amount&.finite? && amount.positive? && attrs[:bank_id].present?
      @swift.errors.add(:deposited_amount, 'and a valid bank are required')
      @banks = Bank.all
      return render :edit_amount_before_confirm, formats: [:turbo_stream], status: :unprocessable_entity
    end
    @swift.with_lock do
      return head :forbidden unless @swift.confirmable_by?(current_user)
      bank = Bank.lock.find(attrs[:bank_id])
      before = bank.account_balance.to_s.to_d
      @swift.update!(bank: bank, deposited_amount: amount, confirmed: true, confirm_at: Time.current)
      @swift.reload
      credit = @swift.deposited_amount.to_s.to_d
      raise ActiveRecord::RecordInvalid.new(@swift) unless credit == amount
      bank.update!(account_balance: before + credit)
      bank.reload
      raise ActiveRecord::RecordInvalid.new(bank) unless bank.account_balance.to_s.to_d == before + credit
      transaction = @swift.transactions.create!(deposit_amount: credit,
        bank: bank, balance_before_transaction: before,
        balance_after_transaction: bank.account_balance)
      transaction.reload
      unless transaction.deposit_amount.to_s.to_d == credit &&
             transaction.balance_before_transaction.to_s.to_d == before &&
             transaction.balance_after_transaction.to_s.to_d == bank.account_balance.to_s.to_d
        raise ActiveRecord::RecordInvalid.new(transaction)
      end
    end
    redirect_to swift_destination, notice: 'Swift confirmed successfully.', status: :see_other
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound => e
    Rails.logger.error("Swift confirmation failed: #{e.class}")
    @swift.reload
    @swift.errors.add(:base, 'Confirmation failed. No bank transaction was saved.')
    @banks = Bank.all
    render :edit_amount_before_confirm, formats: [:turbo_stream], status: :unprocessable_entity
  end

  def reject
    @swift.with_lock do
      return head :forbidden unless @swift.confirmable_by?(current_user)
      @swift.update!(rejected: true, rejected_at: Time.current)
    end
    redirect_to swift_destination, notice: 'Swift rejected successfully.', status: :see_other
  rescue ActiveRecord::RecordInvalid
    redirect_to swift_destination, alert: 'Swift could not be rejected.', status: :see_other
  end

  def toggle_announce
    @swift.with_lock do
      return head :forbidden unless @swift.confirmable_by?(current_user)
      @swift.update!(announce: !@swift.announce?)
    end
    redirect_back fallback_location: swift_destination, notice: 'Announce status updated.', status: :see_other
  rescue ActiveRecord::RecordInvalid
    redirect_to swift_destination, alert: 'Announcement could not be changed.', status: :see_other
  end

  def destroy
    destination = swift_destination
    @swift.with_lock do
      return head :forbidden unless @swift.editable_by?(current_user)
      @swift.destroy!
    end
    redirect_to destination, notice: 'Swift was successfully removed.', status: :see_other
  rescue ActiveRecord::RecordNotDestroyed
    redirect_to destination, alert: 'Swift could not be removed.', status: :see_other
  end

  private

  def set_swift
    @swift = Swift.visible_to(current_user).find(params[:id])
  end

  def require_swift_editor
    head :forbidden unless @swift.editable_by?(current_user)
  end

  def require_swift_accounting
    head :forbidden unless @swift.confirmable_by?(current_user)
  end

  def set_ci_or_project
    if params[:car_id].present?
      return head :forbidden unless Swift.car_creation_allowed?(current_user)
      @car_project = CarImportRecord.car_projects.current.find(params[:car_id])
      @object = 3
    elsif params[:ci_id].present?
      @object = 1
      @ci = Ci.find(params[:ci_id])
      @project = @ci.project
    else
      @object = 2
      @project = Project.find(params[:project_id])
    end
  end

  def build_swift(attributes = {})
    attrs = attributes.except(:project_id)
    case @object
    when 1 then @ci.build_swift(attrs)
    when 2 then @project.swifts.build(attrs)
    when 3 then @car_project.project_swifts.build(attrs)
    end
  end

  def prepare_edit
    @banks = Bank.all
    @projects = Project.all
    if @swift.car_project_id.present?
      @object = 3
      @car_project = @swift.car_project
    elsif @swift.ci_id.present?
      @object = 1
      @ci = @swift.ci
      @project = @ci.project
    else
      @object = 2
      @project = @swift.project
    end
  end

  def swift_destination
    if @swift.car_project_id.present?
      car_path(@swift.car_project_id, anchor: 'project-swifts')
    elsif action_name == 'create' && @project.present?
      project_path(@project)
    else
      swifts_path
    end
  end

  def swift_params
    params.require(:swift).permit(:amount, :bank_id, :currency, :project_id, :from, :note, :advance, documents: [])
  end
end
