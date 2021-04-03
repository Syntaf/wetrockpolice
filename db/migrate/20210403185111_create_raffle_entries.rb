class CreateRaffleEntries < ActiveRecord::Migration[6.0]
  def change
    create_table :raffle_entries do |t|
      t.string :contact
      t.string :email
      t.string :phone_number
      
      t.integer :entries

      t.string :amount_paid
      t.string :order_id

      t.timestamps
    end
  end
end
