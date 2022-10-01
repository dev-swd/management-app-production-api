class CreateQualitygoals < ActiveRecord::Migration[6.1]
  def change
    create_table :qualitygoals do |t|
      t.references :project, index: true, foreign_key: true
      t.string "number"
      t.text "contents"
      t.timestamps
    end
  end
end
