require 'csv'


class Project < ApplicationRecord
  before_save :calculate_risk_based_on_impact_and_likelihood

	has_one :pi
	has_many :cis
	has_many :bookings
	has_many :ballance_projects
	has_many :ballances, through: :ballance_projects
	has_many :payment_orders
	has_many :swifts

  has_secure_password


  validates :number, presence: true,
                   format: { with: /\A(?:14\d{2}-\d{4}|\d{2}-\d{3})\z/, message: "must be in the format 14xx-xxxx or xx-xxx" },
                   uniqueness: true
  validates :password, presence: true, on: :create






  def self.ransackable_attributes(auth_object = nil)
    ['name', 'number']
  end

  def self.ransackable_associations(auth_object = nil)
    []
  end

  def total_booking_quantity
    bookings.sum(:quantity)
  end

  def total_booking_picked_up
    bookings.sum(:picked_up)
  end

  def total_booking_filled
    bookings.sum(:filled)
  end

  def any_booking_stuffing_finished?
    bookings.any? { |booking| booking.filled == booking.quantity }
  end


 DOLLAR_TO_DIRHAM = 3.67

  def total_swifts_amount
    project_swifts_amount = self.swifts.sum do |swift|
      swift.amount * (swift.currency == 'dollar' ? DOLLAR_TO_DIRHAM : 1)
    end

    cis_swifts_amount = self.cis.includes(:swift).sum do |ci|
      ci.swift ? ci.swift.amount * (ci.swift.currency == 'dollar' ? DOLLAR_TO_DIRHAM : 1) : 0
    end

    project_swifts_amount + cis_swifts_amount
  end

    def total_swifts
	    project_swifts = self.swifts
	    cis_swifts = self.cis.includes(:swift).map(&:swift).compact

	    project_swifts + cis_swifts
	  end

	    def sum_balance_swifts
	    swifts.where(advance: [nil, false]).sum do |swift|
		      swift.currency == 'dollar' ? swift.amount * DOLLAR_TO_DIRHAM : swift.amount
		    end
		  end

		  # Method to sum swift amounts from associated cis, with currency conversion
		  def sum_cis_swifts
		    cis.includes(:swift).sum do |ci|
		      if ci.swift
		        ci.swift.currency == 'dollar' ? ci.swift.amount * DOLLAR_TO_DIRHAM : ci.swift.amount
		      else
		        0
		      end
		    end
		  end

		  # Combined method to get total swifts amount in dirham
		  def total_balance_swifts
		    sum_balance_swifts + sum_cis_swifts
		  end

	def remaining_quantity
    pi_quantity = self.pi&.quantity.to_i
    allocated_quantity = self.ballance_projects.sum(:quantity).to_i
    pi_quantity - allocated_quantity
  end


  def self.to_csv
    CSV.generate(headers: true) do |csv|
      # Define headers (omit the last column)
      csv << [
        "Project", "Client", "POD", "Term", "Payment", "PI Number", "PI Date",
        "Quantity", "Unit Price", "Agent", "Commission", "Product", "Packing",
        "Booking", "Line", "Forwarder", "Freight Price", "Inspection",
        "Custom Clearance", "BL Number", "Vessel & Voyage", "BL Date",
        "Net Weight", "Supplier", "PI Number (Supplier)", "Quantity (Supplier)",
        "Packing (Supplier)", "Unit Price (Supplier)"
      ]

      includes(:pi, :bookings, ballance_projects: { ballance: :supplier }).each do |project|
        project.ballance_projects.each_with_index do |bp, index|
          csv << [
            index == 0 ? project.number : "#{project.number} / #{index + 1}",
            project.pi&.customer&.nickname,
            project.pi&.pod,
            project.pi&.incoterm,
            project.swifts.present? ? project.swifts.first.bank.name : (project.cis.any? { |ci| ci.swift.present? } ? project.cis.find { |ci| ci.swift.present? }&.swift&.bank&.name : 'N/A'),
            project.pi&.number,
            project.pi&.issue_date,
            project.pi&.quantity.to_i,
            project.pi&.unit_price.to_i,
            project.pi&.agent,
            project.pi&.commission,
            project.pi&.product,
            project.pi&.packing_type,
            project.bookings.map(&:number).join(' | '),
            project.bookings.map(&:line).join(' | '),
            project.bookings.map(&:forwarder).join(' | '),
            project.bookings.map(&:freight_price).join(' | '),
            project.bookings.map { |b| b.inspection ? "✓" : "✗" }.join(' | '),
            project.bookings.map { |b| b.send_to_line ? "Finished" : b.declaration ? "Declaration" : b.tally ? "Tally" : "N/A" }.join(' | '),
            project.bookings.map(&:bl_number).join(' | '),
            project.bookings.map(&:vessel_name).join(' | '),
            project.bookings.map(&:date_of_bl).join(' | '),
            project.cis.sum(&:net_weight),
            bp.ballance.supplier&.name || '-',
            bp.ballance.spi&.number || '-',
            bp.quantity.to_i,
            bp.ballance.spi&.packing_type || '-',
            bp.ballance.spi&.unit_price.to_i
          ]
        end

        # If there are no ballance_projects, add a single row
        if project.ballance_projects.empty?
          csv << [
            project.number, project.pi&.customer&.nickname, project.pi&.pod, project.pi&.incoterm,
            project.swifts.present? ? project.swifts.first.bank.name : (project.cis.any? { |ci| ci.swift.present? } ? project.cis.find { |ci| ci.swift.present? }&.swift&.bank&.name : 'N/A'),
            project.pi&.number, project.pi&.issue_date, project.pi&.quantity.to_i, project.pi&.unit_price.to_i,
            project.pi&.agent, project.pi&.commission, project.pi&.product, project.pi&.packing_type,
            "-", "-", "-", "-", "-", "-", "-", "-", "-",
            project.cis.sum(&:net_weight), "-", "-", "-", "-", "-"
          ]
        end
      end
    end
  end
	    

  private

	def calculate_risk_based_on_impact_and_likelihood
	    # Define likelihood and impact for each attribute
	    attribute_details = {
	      new_customer:    { likelihood: 1, impact: 5 },
	      new_destination: { likelihood: 6, impact: 7 },
	      shipping:        { likelihood: 3, impact: 7 },
	      exchange:        { likelihood: 3, impact: 7 },
	      supplier_prepaid:{ likelihood: 7, impact: 7 },
	      delivery_failure:{ likelihood: 2, impact: 5 },
	      supplier_credits:{ likelihood: 7, impact: 9 },
	      third_person:    { likelihood: 1, impact: 9 },
	      custom_clearance: { likelihood: 5, impact: 10 },
	      logistic:        { likelihood: 1, impact: 5 },
	      quality:         { likelihood: 7, impact: 9 }
	    }

	    # Initialize max values
	    max_risk_value = 0
	    selected_attribute = nil

	    # Calculate the product of likelihood and impact for each attribute
	    attribute_details.each do |attr, details|
	      if send(attr)
	        risk_value = details[:likelihood] * details[:impact]
	        if risk_value > max_risk_value
	          max_risk_value = risk_value
	          selected_attribute = attr
	        end
	      end
	    end

	    # Set the risk, impact, and likelihood attributes
	    if selected_attribute
	      self.risk = max_risk_value
	      self.impact = attribute_details[selected_attribute][:impact]
	      self.likelihood = attribute_details[selected_attribute][:likelihood]
	      self.selected_risk = selected_attribute
	    else
	      self.risk = 0
	      self.impact = 0
	      self.likelihood = 0
	    end
	  end


end
