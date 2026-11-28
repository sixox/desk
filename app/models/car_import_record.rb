require 'csv'
require 'json'
require 'date'
require 'bigdecimal'

class CarImportRecord < ApplicationRecord
  class ImportError < StandardError; end

  HEADERS = {
    'PIs' => 'Project No.|PI No.|PI Date|Owner|Supplier|Cars|Inspected|Car Advance Paid|Export Docs Ready|Car Balance Paid|On Trucks|Delivered|Next Step|Notes|Estimated Dates',
    'Trucks' => 'Truck|Status|Next Step|Transport Company|Cars|Contract Signed|Transport Advance Paid|Picked Up|Queued at Khorgos|Exited Khorgos|Arrived Nur Zholy|Departed Nur Zholy|Arrived Sarakhs|Inspected at Sarakhs|Issues|Open Incidents|Transport Balance Paid|Customs Declared|Customs Released|Queue Days|Khorgos to Sarakhs Days|Notes|Estimated Dates',
    'Deliveries' => 'Delivery|Status|Transport Company|Destination|Cars|Departed Sarakhs|Delivered|Days|Notes|Estimated Dates',
    'Cars' => 'VIN|Brand|Model|Color|PI No.|Project No.|Owner|Truck|Delivery|Status|Supplier Check|Supplier Media|Sarakhs Check|Sarakhs Media|Destination|Delivered|Final Check|Open Incidents|Hold / Cancel|Notes',
    'Events' => 'Date|Time|Truck|VIN|PI No.|Location|Event Type|Description|Action Needed|Action Done|Estimated Dates',
    'Incidents' => 'Date Found|VIN|Car|Truck|Where|Type|Details|Responsible|Agreed Deduction $|Status|Closed Date|Notes|Estimated Dates'
  }.transform_values { |v| v.split('|').freeze }.freeze

  KEYS = { 'PIs' => 'PI No.', 'Trucks' => 'Truck', 'Deliveries' => 'Delivery', 'Cars' => 'VIN' }.freeze
  DATES = {
    'PIs' => ['PI Date', 'Car Advance Paid', 'Export Docs Ready', 'Car Balance Paid'],
    'Trucks' => ['Contract Signed', 'Transport Advance Paid', 'Picked Up', 'Queued at Khorgos', 'Exited Khorgos', 'Arrived Nur Zholy', 'Departed Nur Zholy', 'Arrived Sarakhs', 'Inspected at Sarakhs', 'Transport Balance Paid', 'Customs Declared', 'Customs Released'],
    'Deliveries' => ['Departed Sarakhs', 'Delivered'], 'Cars' => ['Delivered'],
    'Events' => ['Date'], 'Incidents' => ['Date Found', 'Closed Date']
  }.freeze
  INTS = {
    'PIs' => ['Cars', 'Inspected', 'On Trucks', 'Delivered'],
    'Trucks' => ['Cars', 'Issues', 'Open Incidents', 'Queue Days', 'Khorgos to Sarakhs Days'],
    'Deliveries' => ['Cars', 'Days'], 'Cars' => ['Open Incidents']
  }.freeze
  LINKS = {
    'Cars' => { 'PI No.' => 'PIs', 'Truck' => 'Trucks', 'Delivery' => 'Deliveries' },
    'Events' => { 'PI No.' => 'PIs', 'Truck' => 'Trucks', 'VIN' => 'Cars' },
    'Incidents' => { 'Truck' => 'Trucks', 'VIN' => 'Cars' }
  }.freeze

  scope :current, -> { where(active: true) }
  scope :pis, -> { where(dataset: 'PIs') }
  scope :car_projects, -> { where(dataset: 'CarProjects') }
  has_many :project_swifts, class_name: 'Swift', foreign_key: :car_project_id,
           inverse_of: :car_project, dependent: :restrict_with_error

  def self.sync_car_projects!(parsed)
    numbers = %w[PIs Cars].flat_map do |name|
      parsed.fetch(name).filter_map { |_, fields| fields['Project No.'].presence }
    end.uniq
    existing = car_projects.index_by(&:external_key)
    numbers.each do |number|
      record = existing.delete(number) || car_projects.new(external_key: number)
      record.update!(payload: JSON.generate('Project No.' => number), active: true)
    end
    car_projects.where(id: existing.values.map(&:id)).update_all(active: false, updated_at: Time.current)
  end

  def fields
    JSON.parse(payload)
  end

  def estimated?(key)
    fields['Estimated Dates'].to_s.split(';').map(&:strip).include?(key)
  end

  def pi_label
    "#{fields['Project No.']} · #{fields['PI No.']}"
  end

  def self.snapshot
    current.order(:id).to_a.group_by(&:dataset)
  end

  def self.parse_file(name, file)
    raise ImportError, "Missing #{name}.csv" unless file.respond_to?(:read) && file.respond_to?(:original_filename)
    raise ImportError, "Expected #{name}.csv" unless file.original_filename == "#{name}.csv"
    file.rewind
    raw = file.read(10 * 1024 * 1024 + 1).to_s
    raise ImportError, "#{name}.csv exceeds 10 MB" if raw.bytesize > 10 * 1024 * 1024
    raw = raw.force_encoding('UTF-8')
    raise ImportError, "#{name}.csv is not UTF-8" unless raw.valid_encoding?
    rows = CSV.parse(raw.delete_prefix("\uFEFF"))
    expected = HEADERS.fetch(name)
    raise ImportError, "#{name}.csv: incorrect headers/order" unless rows.shift == expected
    seen = {}
    rows.map.with_index(2) do |row, line|
      error = ->(message) { raise ImportError, "#{name}.csv row #{line}: #{message}" }
      error.call('incorrect column count') unless row.length == expected.length
      values = expected.zip(row).to_h.transform_values { |v| v.nil? || v.strip.empty? ? nil : v }
      DATES.fetch(name).each do |column|
        v = values[column]
        next unless v
        error.call("invalid #{column}") unless v.match?(/\A\d{4}-\d{2}-\d{2}\z/) && Date.valid_date?(*v.split('-').map(&:to_i))
      end
      INTS.fetch(name, []).each do |column|
        v = values[column]
        next unless v
        error.call("invalid #{column}") unless v.match?(/\A\d+\z/)
        values[column] = v.to_i
      end
      if (v = values['Time']) && !v.match?(/\A(?:[01]\d|2[0-3]):[0-5]\d\z/)
        error.call('invalid Time')
      end
      if (v = values['Agreed Deduction $'])
        error.call('invalid Agreed Deduction $') unless v.match?(/\A[+-]?\d+(?:\.\d+)?\z/) && BigDecimal(v).finite?
      end
      estimates = values['Estimated Dates'].to_s.split(';').map(&:strip).reject(&:empty?)
      error.call('unknown estimated date column') unless (estimates - DATES.fetch(name)).empty?
      key = KEYS[name] ? values[KEYS[name]] : (line - 1).to_s
      error.call('missing unique key') if key.nil? || key.empty?
      error.call('key exceeds 191 characters') if key.length > 191
      error.call('duplicate key') if seen[key.downcase]
      seen[key.downcase] = true
      [key, values]
    end
  rescue CSV::MalformedCSVError => e
    raise ImportError, "#{name}.csv: #{e.message}"
  end

  def self.parse_snapshot(files)
    parsed = HEADERS.keys.to_h { |name| [name, parse_file(name, files[name])] }
    keysets = parsed.transform_values { |rows| rows.to_h }
    LINKS.each do |source, links|
      parsed[source].each do |key, fields|
        links.each do |column, target|
          value = fields[column]
          next unless value
          raise ImportError, "#{source} #{key}: #{column} #{value} not found in #{target}" unless keysets[target].key?(value)
        end
      end
    end
    parsed['Cars'].each do |key, car|
      pi = keysets['PIs'][car['PI No.']]
      if pi && car['Project No.'] && pi['Project No.'] != car['Project No.']
        raise ImportError, "Cars #{key}: project differs from PI project"
      end
    end
    project_numbers = %w[PIs Cars].flat_map do |name|
      parsed.fetch(name).filter_map { |_, fields| fields['Project No.'] }
    end.uniq
    raise ImportError, 'Project No. exceeds 191 characters' if project_numbers.any? { |n| n.length > 191 }
    raise ImportError, 'Conflicting project number capitalization' if project_numbers.map(&:downcase).uniq.size != project_numbers.size
    parsed
  end

  def self.import!(files, user:)
    raise ImportError, 'Car access required' unless user.car_access?
    parsed = parse_snapshot(files)
    transaction do
      meta = lock.find_by!(dataset: 'meta', external_key: 'snapshot')
      parsed.each do |name, rows|
        scope = where(dataset: name)
        if KEYS.key?(name)
          existing = scope.index_by(&:external_key)
          rows.each do |key, fields|
            record = existing.delete(key) || scope.new(external_key: key)
            record.update!(payload: JSON.generate(fields), active: true)
          end
          where(id: existing.values.map(&:id)).update_all(active: false, updated_at: Time.current)
        else
          scope.delete_all
          rows.each { |key, fields| scope.create!(external_key: key, payload: JSON.generate(fields), active: true) }
        end
      end
      sync_car_projects!(parsed)
      meta.update!(payload: JSON.generate({ 'imported_at' => Time.current.iso8601, 'user_id' => user.id, 'counts' => parsed.transform_values(&:size) }))
    end
    parsed.transform_values(&:size)
  end
end
