class RebuildSalaryArchivesFixManagerConfirmedByFk < ActiveRecord::Migration[7.0]
  def up
    if mysql?
      # 1) اگر FK اشتباه/قدیمی هست حذفش کن (با rescue چون اسم FK ممکنه متفاوت باشه)
      remove_foreign_key :salary_archives, column: :manager_confirmed_by_id rescue nil

      # 2) nullable کردن ستون (مشکل اصلی)
      change_column_null :salary_archives, :manager_confirmed_by_id, true

      # 3) FK درست به users
      add_foreign_key :salary_archives, :users, column: :manager_confirmed_by_id
    else
      # SQLite / سایر DB ها: همون روش rebuild قبلی (اگر خواستی نگه داریم)
      execute("PRAGMA foreign_keys = OFF;") if sqlite?

      create_table :salary_archives_new do |t|
        t.integer  :user_id, null: false
        t.integer  :shamsi_month_id, null: false
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
        t.integer  :manager_confirmed_by_id, null: true
        t.datetime :created_at, null: false
        t.datetime :updated_at, null: false
      end

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

      drop_table :salary_archives
      rename_table :salary_archives_new, :salary_archives

      add_index :salary_archives, :manager_confirmed_by_id, name: "index_salary_archives_on_manager_confirmed_by_id"
      add_index :salary_archives, :shamsi_month_id, name: "index_salary_archives_on_shamsi_month_id"
      add_index :salary_archives, :user_id, name: "index_salary_archives_on_user_id"
      add_index :salary_archives, [:user_id, :shamsi_month_id],
                unique: true,
                name: "index_salary_archives_on_user_id_and_shamsi_month_id"

      add_foreign_key :salary_archives, :users, column: :user_id
      add_foreign_key :salary_archives, :shamsi_months, column: :shamsi_month_id
      add_foreign_key :salary_archives, :users, column: :manager_confirmed_by_id

      execute("PRAGMA foreign_keys = ON;") if sqlite?
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  private

  def sqlite?
    ActiveRecord::Base.connection.adapter_name.downcase.include?("sqlite")
  end

  def mysql?
    ActiveRecord::Base.connection.adapter_name.downcase.include?("mysql")
  end
end
