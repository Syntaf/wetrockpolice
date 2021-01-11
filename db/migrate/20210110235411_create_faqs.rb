class CreateFaqs < ActiveRecord::Migration[6.0]
  def change
    create_table :faqs do |t|
      t.string :question, null: false, default: ''
      t.text :answer, null: false, default: ''
      t.references :watched_area

      t.timestamps
    end
  end
end
