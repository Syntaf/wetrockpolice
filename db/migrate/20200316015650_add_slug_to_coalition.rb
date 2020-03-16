class AddSlugToCoalition < ActiveRecord::Migration[5.2]
  def change
    add_column :local_climbing_orgs, :slug, :string, null: false
    add_index :local_climbing_orgs, :slug, unique: true
  end
end
