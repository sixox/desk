class RebuildSalaryArchivesFixManagerConfirmedByFk < ActiveRecord::Migration[7.0]
  def up
    # SQLite can get stuck if foreign_keys are enforced while we rebuild
    execute("PRAGMA foreign_keys = OFF;") if sqlite?

    # 1) Create new table with correct schema
    create_table :salary_archives_new do |t|
      t.integer  :user_id, null: false
      t.integer  :shamsi_month_id, null: false

      # Keep same nullability/default as your current table
      t.integer  :status, null: true, default: nil

      t.integer  :total_work_minutes, null: true, default: nil
      t.integer  :overtime_minutes, null: true, default: nil
      t.integer  :deficit_minutes, null: true, default: nil
      t.integer  :manual_overtime_minutes, null: true, default: nil
      t.integer  :manual_deficit_minutes, null: true, default: nil

      t.decimal  :bonus, null: true, default: nil
      t.decimal  :penalty, null: true, default: nil
      t.text     :notes, null: true

      t.datetime :manager_confirmed_at, null: true

      # IMPORTANT FIX: must be nullable
      t.integer  :manager_confirmed_by_id, null: true

      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
    end

    # 2) Copy data (safe even if table empty)
    execute <<~SQL
      INSERT INTO salary_archives_new (
        id, user_id, shamsi_month_id, status,
        total_work_minutes, overtime_minutes, deficit_minutes,
        manual_overtime_minutes, manual_deficit_minutes,
        bonus, penalty, notes,
        manager_confirmed_at, manager_confirmed_by_id,
        created_at, updated_at
      )
      SELECT
        id, user_id, shamsi_month_id, status,
        total_work_minutes, overtime_minutes, deficit_minutes,
        manual_overtime_minutes, manual_deficit_minutes,
        bonus, penalty, notes,
        manager_confirmed_at, manager_confirmed_by_id,
        created_at, updated_at
      FROM salary_archives;
    SQL

    # 3) Drop old table and rename new
    drop_table :salary_archives
    rename_table :salary_archives_new, :salary_archives

    # 4) Recreate indexes (keep the exact ones you currently have)
    add_index :salary_archives, :manager_confirmed_by_id, name: "index_salary_archives_on_manager_confirmed_by_id"
    add_index :salary_archives, :shamsi_month_id, name: "index_salary_archives_on_shamsi_month_id"
    add_index :salary_archives, :user_id, name: "index_salary_archives_on_user_id"

    # Strongly recommended: enforce uniqueness at DB level (matches your validation)
    add_index :salary_archives, [:user_id, :shamsi_month_id],
              unique: true,
              name: "index_salary_archives_on_user_id_and_shamsi_month_id"

    # 5) Recreate correct foreign keys
    add_foreign_key :salary_archives, :users, column: :user_id
    add_foreign_key :salary_archives, :shamsi_months, column: :shamsi_month_id
    add_foreign_key :salary_archives, :users, column: :manager_confirmed_by_id

    execute("PRAGMA foreign_keys = ON;") if sqlite?
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  private

  def sqlite?
    ActiveRecord::Base.connection.adapter_name.downcase.include?("sqlite")
  end
end
