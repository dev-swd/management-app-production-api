class CreateAudits < ActiveRecord::Migration[6.1]
  def change
    create_table :audits do |t|
      t.references :project, index: true, foreign_key: true
      t.string "kinds"
      t.integer "number"
      t.bigint "auditor_id"
      t.date "audit_date"
      t.string "title"
      t.text "contents"
      t.string "result"
      t.bigint "accept_id"
      t.date "accept_date"
      t.timestamps
    end
  end
end
