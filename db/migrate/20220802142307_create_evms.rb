class CreateEvms < ActiveRecord::Migration[6.1]
  def change
    create_table :evms do |t|
      t.references :progressreport, index: true, foreign_key: true
      t.string "level"
      t.bigint "phase_id"
      t.date "date_fr"
      t.date "date_to"
      t.decimal "bac", precision: 8, scale: 2
      t.decimal "pv", precision: 8, scale: 2
      t.decimal "ev", precision: 8, scale: 2
      t.decimal "ac", precision: 8, scale: 2
      t.decimal "sv", precision: 8, scale: 2
      t.decimal "cv", precision: 8, scale: 2
      t.decimal "spi", precision: 8, scale: 2
      t.decimal "cpi", precision: 8, scale: 2
      t.decimal "pv_sum", precision: 8, scale: 2
      t.decimal "ev_sum", precision: 8, scale: 2
      t.decimal "ac_sum", precision: 8, scale: 2
      t.decimal "sv_sum", precision: 8, scale: 2
      t.decimal "cv_sum", precision: 8, scale: 2
      t.decimal "spi_sum", precision: 8, scale: 2
      t.decimal "cpi_sum", precision: 8, scale: 2
      t.decimal "etc", precision: 8, scale: 2
      t.decimal "eac", precision: 8, scale: 2
      t.decimal "vac", precision: 8, scale: 2
      t.timestamps
    end
  end
end
