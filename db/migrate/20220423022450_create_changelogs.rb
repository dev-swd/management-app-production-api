class CreateChangelogs < ActiveRecord::Migration[6.1]
  def change
    create_table :changelogs do |t|
      t.references :project, index: true, foreign_key: true
      t.integer "number"
      t.bigint "changer_id"
      t.date "change_date"
      t.text "contents"
      t.timestamps
    end
  end
end
