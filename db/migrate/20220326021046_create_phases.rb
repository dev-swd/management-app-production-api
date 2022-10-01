class CreatePhases < ActiveRecord::Migration[6.1]
  def change
    create_table :phases do |t|
      t.references :project, index: true, foreign_key: true
      t.string "number"
      t.string "name"
      t.date "planned_periodfr"
      t.date "planned_periodto"
      t.date "actual_periodfr"
      t.date "actual_periodto"
      t.text "deliverables"
      t.text "criteria"
      t.integer "review_count"
      t.bigint "planned_cost"
      t.decimal "planned_workload", precision: 5, scale: 2
      t.bigint "planned_outsourcing_cost"
      t.decimal "planned_outsourcing_workload", precision: 5, scale: 2
      t.bigint "actual_cost"
      t.decimal "actual_workload", precision: 5, scale: 2
      t.bigint "actual_outsourcing_cost"
      t.decimal "actual_outsourcing_workload", precision: 5, scale: 2
      t.string "ship_number"
      t.date "accept_comp_date"
      t.timestamps
    end
  end
end
