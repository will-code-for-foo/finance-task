class ChangeAmountCentsToBigint < ActiveRecord::Migration[8.1]
  def change
    change_column :transactions, :amount_cents, :bigint
    change_column :users, :balance_cents, :bigint
  end
end
