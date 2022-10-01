class CreateTaskactuals < ActiveRecord::Migration[6.1]
  def change
    create_table :taskactuals do |t|
      t.references :progressreport, index: true, foreign_key: true
      t.references :taskcopy, index: true, foreign_key: true
      t.decimal "total_workload", precision: 6, scale: 2
      t.decimal "overtime_workload", precision: 6, scale: 2
      t.decimal "after_total_workload", precision: 6, scale: 2
      t.decimal "after_overtime_workload", precision: 6, scale: 2
      t.timestamps
    end
  end
end
