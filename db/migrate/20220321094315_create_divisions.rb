class CreateDivisions < ActiveRecord::Migration[6.1]
  def change
    create_table :divisions do |t|
      t.references :department, index: true, foreign_key: true
      t.string :code
      t.string :name
      t.timestamps
    end
  end
end
