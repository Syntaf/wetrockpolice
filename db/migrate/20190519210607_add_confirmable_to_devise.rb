class AddConfirmableToDevise < ActiveRecord::Migration[5.1]
  def self.up
    add_column :users, :confirmation_token, :string
    add_column :users, :confirmed_at, :datetime
    add_column :users, :confirmation_sent_at, :datetime

    add_index :users, :confirmation_token, unique: true

    # Updating all existing users so they do not need to confirm
    User.update_all confirmed_at: DateTime.now
  end

  def self.down
    remove_index :users, :confirmation_token
    remove_columns :users, :confirmation_token, :confirmed_at, :confirmation_sent_at
  end
end
