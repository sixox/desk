require 'json'

class AddCarProjectToSwifts < ActiveRecord::Migration[7.0]

  class ImportRow < ActiveRecord::Base
    self.table_name = 'car_import_records'
  end

  def up
    add_reference :swifts, :car_project,
                  foreign_key: {
                    to_table: :car_import_records
                  }

    projects = {}

    ImportRow.where(dataset: %w[PIs Cars]).find_each do |row|

      number = JSON.parse(row.payload)['Project No.'].presence

      next unless number

      projects[number] =
        projects.fetch(number, false) || row.active?

    end

    projects.each do |number, active|

      row = ImportRow.find_or_initialize_by(
        dataset: 'CarProjects',
        external_key: number
      )

      row.update!(
        payload: JSON.generate('Project No.' => number),
        active: active
      )

    end
  end

  def down
    remove_reference :swifts, :car_project,
                     foreign_key: {
                       to_table: :car_import_records
                     }
  end

end