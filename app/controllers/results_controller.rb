class ResultsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_kpi_list

  def bulk_new
    @targets = @kpi_list.targets.includes(results: :kpi)

    @targets.each do |target|
      4.times do
        result = target.results.build
        result.build_kpi
      end
    end
  end

def bulk_create
  success = true
  flash[:alert] = []

  params[:targets]&.each do |target_id, result_data_array|
    target = @kpi_list.targets.find(target_id)

    result_data_array.each do |_, result_data|
      description = result_data[:description].to_s.strip
      kpi_value   = result_data.dig(:kpi, :comment).to_s.strip

      # Skip completely empty rows
      next if description.blank? && kpi_value.blank?

      # Prevent KPI-only row (missing description)
      if description.blank? && kpi_value.present?
        success = false
        flash[:alert] << "Target ##{target_id}: KPI comment requires a result description."
        next
      end

      result = target.results.build(description: description)
      result.build_kpi(comment: kpi_value) if kpi_value.present?

      unless result.save
        success = false
        flash[:alert] << "Failed to save result for target ##{target_id}."
      end
    end
  end

  if success
    redirect_to root_path, notice: "All valid results and KPIs saved."
  else
    flash.now[:alert] = flash[:alert].join("<br>").html_safe
    bulk_new
    render :bulk_new, status: :unprocessable_entity
  end
end


  private

  def set_kpi_list
    @kpi_list = current_user.kpi_lists.find(params[:kpi_list_id])
  end
end
