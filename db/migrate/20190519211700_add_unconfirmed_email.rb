class AddUnconfirmedEmail < ActiveRecord::Migration[5.1]
  def self.up
    add_column :users, :unconfirmed_email, :string
  end

  def self.down
    remove_columns :users, :unconfirmed_email, :string
  end
end
