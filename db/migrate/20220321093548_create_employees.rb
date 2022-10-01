class CreateEmployees < ActiveRecord::Migration[6.1]
  def change
    create_table :employees do |t|
      t.string "number"
      t.string "name"
      t.string "name2"
      t.date "birthday"
      t.string "address"
      t.string "phone"
      t.date "joining_date"
      t.bigint "division_id"
      t.bigint "devise_id"
      t.string "authority"
      t.timestamps
    end
  end
end
