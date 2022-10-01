class CreatePhaseactuals < ActiveRecord::Migration[6.1]
  def change
    create_table :phaseactuals do |t|
      t.references :progressreport, index: true, foreign_key: true
      t.references :phasecopy, index: true, foreign_key: true
      t.date "periodfr"
      t.date "periodto"
      t.bigint "total_cost"
      t.decimal "total_workload", precision: 6, scale: 2
      t.decimal "overtime_workload", precision: 6, scale: 2
      t.decimal "after_total_workload", precision: 6, scale: 2
      t.decimal "after_overtime_workload", precision: 6, scale: 2
      t.timestamps
    end
  end
end
