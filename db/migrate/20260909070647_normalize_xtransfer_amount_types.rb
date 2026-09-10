# db/migrate/XXXXXXXXXXXXXX_normalize_xtransfer_amount_types.rb

class NormalizeXtransferAmountTypes < ActiveRecord::Migration[7.0]
  def change
    change_column :xtransfers,
                  :sender_amount,
                  :integer,
                  limit: 8

    change_column :xtransfers,
                  :receiver_amount,
                  :integer,
                  limit: 8

    change_column :xtransfers,
                  :wage,
                  :integer,
                  limit: 8

    change_column :xtransfers,
                  :sender_charge,
                  :integer,
                  limit: 8,
                  default: 0

    change_column :xtransfers,
                  :receiver_charge,
                  :integer,
                  limit: 8,
                  default: 0

    change_column :xtransfers,
                  :sender_total,
                  :integer,
                  limit: 8,
                  default: 0

    change_column :xtransfers,
                  :receiver_total,
                  :integer,
                  limit: 8,
                  default: 0

    change_column :xtransfers,
                  :sender_amount_to,
                  :integer,
                  limit: 8

    change_column :xtransfers,
                  :receiver_amount_to,
                  :integer,
                  limit: 8

    change_column :xtransfers,
                  :sender_exchange_rate,
                  :float

    change_column :xtransfers,
                  :receiver_exchange_rate,
                  :float
  end
end