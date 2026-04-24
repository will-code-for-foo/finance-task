class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users, id: :uuid do |t|
      t.string :email, null: false
      t.integer :balance_cents, null: false, default: 0

      t.timestamps
    end

    add_index :users, :email, unique: true
    add_check_constraint :users, "balance_cents >= 0", name: "check_users_balance_cents_non_negative"
  end
end
