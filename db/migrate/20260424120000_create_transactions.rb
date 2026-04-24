class CreateTransactions < ActiveRecord::Migration[8.1]
  def change
    create_table :transactions, id: :uuid do |t|
      t.uuid :sender_id, null: true
      t.uuid :receiver_id, null: true
      t.integer :amount_cents, null: false
      t.string :transaction_type, null: false

      t.datetime :created_at, null: false
    end

    add_index :transactions, :sender_id
    add_index :transactions, :receiver_id

    add_foreign_key :transactions, :users, column: :sender_id
    add_foreign_key :transactions, :users, column: :receiver_id

    add_check_constraint :transactions, "amount_cents > 0", name: "check_transactions_amount_cents_positive"
  end
end
