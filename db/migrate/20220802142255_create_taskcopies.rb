class CreateTaskcopies < ActiveRecord::Migration[6.1]
  def change
    create_table :taskcopies do |t|
      t.references :progressreport, index: true, foreign_key: true
      t.bigint "number"
      t.bigint "phase_id"
      t.bigint "task_id"
      t.string "task_name"
      t.string "worker_name"
      t.boolean "outsourcing", null: false, default: false
      t.decimal "planned_workload", precision: 6, scale: 2
      t.date "planned_periodfr"
      t.date "planned_periodto"
      t.decimal "actual_workload", precision: 6, scale: 2
      t.date "actual_periodfr"
      t.date "actual_periodto"
      t.string "tag"
      t.timestamps
    end
  end
end
