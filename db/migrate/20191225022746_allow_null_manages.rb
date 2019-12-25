class AllowNullManages < ActiveRecord::Migration[5.1]
  def change
    change_column_null :users, :manages, true
  end
end
