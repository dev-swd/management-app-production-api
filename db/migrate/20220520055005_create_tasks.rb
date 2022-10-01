class CreateTasks < ActiveRecord::Migration[6.1]
  def change
    create_table :tasks do |t|
      t.references :phase, index: true, foreign_key: true
      t.bigint "number"
      t.string "name"
      t.bigint "worker_id"
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
