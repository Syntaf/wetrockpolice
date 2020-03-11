class AddSlugTypeToWatchedArea < ActiveRecord::Migration[5.2]
  def change
    change_column :watched_areas, :slug, :string, null: false
    add_index :watched_areas, :slug, unique: true
  end
end
