class CreateLocalClimbingOrgs < ActiveRecord::Migration[5.2]
  def change
    create_table :local_climbing_orgs do |t|
      t.string
      t.timestamps
    end

    add_reference :watched_areas, :local_climbing_org, index: true
  end
end
