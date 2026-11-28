require "set"

class CarsController < ApplicationController
  before_action :authenticate_user!
  before_action :require_car_access

  COLUMNS = {
    'PIs' => ['Project No.', 'PI No.', 'Owner', 'Supplier', 'Cars', 'Delivered', 'Next Step'],
    'Cars' => ['VIN', 'Brand', 'Model', 'Color', 'PI No.', 'Truck', 'Delivery', 'Status'],
    'Trucks' => ['Truck', 'Status', 'Transport Company', 'Cars', 'Next Step', 'Arrived Sarakhs', 'Customs Released'],
    'Deliveries' => ['Delivery', 'Status', 'Transport Company', 'Destination', 'Cars', 'Delivered'],
    'Events' => ['Date', 'Time', 'Truck', 'VIN', 'PI No.', 'Event Type', 'Description'],
    'Incidents' => ['Date Found', 'VIN', 'Truck', 'Type', 'Details', 'Status', 'Agreed Deduction $']
  }.freeze

  def index
    @snapshot = CarImportRecord.snapshot
    @tab = (['Projects'] + CarImportRecord::HEADERS.keys).include?(params[:tab]) ? params[:tab] : 'Projects'
    @project = params[:project].to_s.presence
    @pi = params[:pi].to_s.presence
    @query = params[:search].to_s.strip
    @status = params[:status].to_s.presence
    all_pis = @snapshot.fetch('PIs', [])
    @project_names = all_pis.map { |r| r.fields['Project No.'] }.compact.uniq.sort
    pis = all_pis.select { |r| (!@project || r.fields['Project No.'] == @project) && (!@pi || r.external_key == @pi) }
    pi_keys = pis.map(&:external_key)
    vehicles = @snapshot.fetch('Cars', [])
    if @project || @pi
      vehicles = vehicles.select do |r|
        pi_keys.include?(r.fields['PI No.']) || (!@pi && r.fields['PI No.'].blank? && r.fields['Project No.'] == @project)
      end
    end
    @filtered = @snapshot.dup
    @filtered['PIs'] = pis
    @filtered['Cars'] = vehicles
    if @project || @pi
      vins = vehicles.map(&:external_key).to_set
      trucks = vehicles.filter_map { |r| r.fields['Truck'] }.to_set
      deliveries = vehicles.filter_map { |r| r.fields['Delivery'] }.to_set
      @filtered['Trucks'] = @snapshot.fetch('Trucks', []).select { |r| trucks.include?(r.external_key) }
      @filtered['Deliveries'] = @snapshot.fetch('Deliveries', []).select { |r| deliveries.include?(r.external_key) }
      %w[Events Incidents].each do |name|
        @filtered[name] = @snapshot.fetch(name, []).select do |r|
          f = r.fields
          vins.include?(f['VIN']) || trucks.include?(f['Truck']) || pi_keys.include?(f['PI No.'])
        end
      end
    end
    if @tab == 'Projects'
      projects = pis.group_by { |r| r.fields['Project No.'] }
      projects = projects.select do |name, records|
        ([name] + records.flat_map { |r| r.fields.values }).join(' ').downcase.include?(@query.downcase) ||
          vehicles.any? { |v| v.fields['Project No.'] == name && v.fields.values.join(' ').downcase.include?(@query.downcase) }
      end if @query.present?
      @projects = Kaminari.paginate_array(projects.sort_by { |name, _| name.to_s }).page(params[:page]).per(12)
    else
      @columns = COLUMNS.fetch(@tab)
      records = @filtered.fetch(@tab, [])
      @statuses = records.map { |r| r.fields['Status'].presence || 'Unknown' }.uniq.sort if CarImportRecord::HEADERS.fetch(@tab).include?('Status')
      records = records.select { |r| (r.fields['Status'].presence || 'Unknown') == @status } if @status
      records = records.select { |r| r.fields.values.join(' ').downcase.include?(@query.downcase) } if @query.present?
      @records = Kaminari.paginate_array(records).page(params[:page]).per(30)
      if @tab == 'PIs'
        cu = current_user
        base = PaymentOrder.car_payment_visible_scope(cu)
        unless cu.admin? || cu.ceo? || cu.cob? || cu.accounting? || (cu.is_manager && cu.procurement?)
          role_ids = if cu.logistics?
            PaymentOrder.joins(:user).where(users: {role: %w[sales procurement logistics]}).where.not(user_id: 9).select(:id)
          else
            PaymentOrder.filtered_by_role(cu).where.not(user_id: 9).select(:id)
          end
          base = base.where(id: role_ids).or(base.where(user_id: cu.id))
          base = base.or(PaymentOrder.car_payment_visible_scope(cu).where(id: PaymentOrder.hamed_queue_for(cu).select(:id))) if cu.id == 15
        end
        @linked_pos = base.where(car_pi_id: @records.map(&:id)).order(created_at: :desc).group_by(&:car_pi_id)
      end
    end
  end

  def import
    files = params[:files]
    raise CarImportRecord::ImportError, 'Select all six CSV files' unless files.is_a?(ActionController::Parameters)
    counts = CarImportRecord.import!(files, user: current_user)
    redirect_to cars_path, notice: "Snapshot updated: #{counts.map { |name, count| "#{name}: #{count}" }.join(' · ')}", status: :see_other
  rescue CarImportRecord::ImportError => e
    redirect_to cars_path, alert: e.message, status: :see_other
  rescue ActiveRecord::ActiveRecordError => e
    Rails.logger.error("Cars import failed: #{e.class}")
    redirect_to cars_path, alert: 'Import failed. Existing data was not changed.', status: :see_other
  end

  private

  def require_car_access
    head :forbidden unless current_user.car_access?
  end
end
