class AddNoteAndAdnaceToSwifts < ActiveRecord::Migration[7.0]
  def change
    add_column :swifts, :note, :text
    add_column :swifts, :advance, :boolean
  end
end
