class AddCarImport < ActiveRecord::Migration[7.0]
 def up
  add_column :users,
  :car_access,
  :boolean,
  default: false,
  null: false

  create_table :car_import_records do |t|
    t.string :dataset, limit: 24, null: false
    t.string :external_key, limit: 191, null: false
    t.text :payload, limit: 16.megabytes, null: false
    t.boolean :active, default: true, null: false
    t.timestamps
  end

  add_index :car_import_records,
  [:dataset, :external_key],
  unique: true,
  name: "idx_car_import_identity"

  add_index :car_import_records,
  [:dataset, :active]

  add_reference :payment_orders,
  :car_pi,
  foreign_key: {
    to_table: :car_import_records
  }

  execute <<~SQL
  INSERT INTO car_import_records
  (
    dataset,
    external_key,
    payload,
    active,
    created_at,
    updated_at
    )
  VALUES
  (
    'meta',
    'snapshot',
    '{}',
    #{connection.quote(true)},
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
    )
  SQL
end

def down
  remove_reference :payment_orders,
  :car_pi,
  foreign_key: {
   to_table: :car_import_records
 }

 drop_table :car_import_records
 remove_column :users, :car_access
end

end



