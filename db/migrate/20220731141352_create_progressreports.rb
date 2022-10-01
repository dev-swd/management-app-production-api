class CreateProgressreports < ActiveRecord::Migration[6.1]
  def change
    create_table :progressreports do |t|
      t.references :project, index: true, foreign_key: true
      t.bigint "make_id"
      t.string "totaling_day"
      t.string "outsourcing"
      t.date "development_period_fr"
      t.date "development_period_to"
      t.timestamps
    end
  end
end
