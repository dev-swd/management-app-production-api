class CreatePhasecopies < ActiveRecord::Migration[6.1]
  def change
    create_table :phasecopies do |t|
      t.references :progressreport, index: true, foreign_key: true
      t.bigint "phase_id"
      t.string "number"
      t.string "name"
      t.date "planned_periodfr"
      t.date "planned_periodto"
      t.date "actual_periodfr"
      t.date "actual_periodto"
      t.bigint "planned_cost"
      t.decimal "planned_workload", precision: 5, scale: 2
      t.bigint "planned_outsourcing_cost"
      t.decimal "planned_outsourcing_workload", precision: 5, scale: 2
      t.bigint "actual_cost"
      t.decimal "actual_workload", precision: 5, scale: 2
      t.bigint "actual_outsourcing_cost"
      t.decimal "actual_outsourcing_workload", precision: 5, scale: 2
      t.timestamps
    end
  end
end
