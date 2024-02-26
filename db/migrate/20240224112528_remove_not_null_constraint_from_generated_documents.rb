class RemoveNotNullConstraintFromGeneratedDocuments < ActiveRecord::Migration[7.0]
  def change
    change_column_null :generated_documents, :pi_id, true
    change_column_null :generated_documents, :ci_id, true
  end
end
