class AddCurrenciesToXtransfers < ActiveRecord::Migration[7.0]
  def change
    add_reference :xtransfers,
                  :sender_currency,
                  foreign_key: { to_table: :currencies },
                  null: false

    add_reference :xtransfers,
                  :receiver_currency,
                  foreign_key: { to_table: :currencies },
                  null: false
  end
end