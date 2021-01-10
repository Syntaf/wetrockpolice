class AddRenderFieldsToWatchedAreas < ActiveRecord::Migration[6.0]
  def change
    add_column :watched_areas, :park_type_word, :string, null: false, default: 'area'
    add_column :watched_areas, :info_bubble_excerpt, :text, null: false, default: ''
    add_column :watched_areas, :landing_paragraph, :text, null: false, default: ''
    add_column :watched_areas, :photo_credit_name, :string, null: false, default: ''
    add_column :watched_areas, :photo_credit_link, :string, null: false, default: ''
  end
end
