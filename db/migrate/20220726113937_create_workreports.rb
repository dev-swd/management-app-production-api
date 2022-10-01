class CreateWorkreports < ActiveRecord::Migration[6.1]
  def change
    create_table :workreports do |t|
      t.references :dailyreport, index: true, foreign_key: true
      t.integer "number"
      t.bigint "project_id"
      t.bigint "phase_id"
      t.bigint "task_id"
      t.integer "hour"
      t.integer "minute"
      t.integer "over_h"
      t.integer "over_m"
      t.string "comments"
      t.timestamps
    end
  end
end
