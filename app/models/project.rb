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


  validates :number, presence: true, format: { with: /\A14\d{2}-\d{4}\z/, message: "must be in the format '14xx-xxxx'" }, uniqueness: true
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
