class CreateReports < ActiveRecord::Migration[6.1]
  def change
    create_table :reports do |t|
      t.references :project, index: true, foreign_key: true
      t.string "approval"
      t.date "approval_date"
      t.date "make_date"
      t.bigint "make_id"
      t.date "delivery_date"
      t.bigint "actual_work_cost"
      t.decimal "actual_workload", precision: 5, scale: 2
      t.bigint "actual_purchasing_cost"
      t.bigint "actual_outsourcing_cost"
      t.decimal "actual_outsourcing_workload", precision: 5, scale: 2
      t.bigint "actual_expenses_cost"
      t.bigint "gross_profit"
      t.string "customer_property_accept_result"
      t.string "customer_property_accept_remarks"
      t.string "customer_property_used_result"
      t.string "customer_property_used_remarks"
      t.string "purchasing_goods_accept_result"
      t.string "purchasing_goods_accept_remarks"
      t.string "outsourcing_evaluate1"
      t.string "outsourcing_evaluate_remarks1"
      t.string "outsourcing_evaluate2"
      t.string "outsourcing_evaluate_remarks2"
      t.integer "communication_count"
      t.integer "meeting_count"
      t.integer "phone_count"
      t.integer "mail_count"
      t.integer "fax_count"
      t.integer "design_changes_count"
      t.integer "specification_change_count"
      t.integer "design_error_count"
      t.integer "others_count"
      t.integer "improvement_count"
      t.integer "corrective_action_count"
      t.integer "preventive_measures_count"
      t.integer "project_meeting_count"
      t.text "statistical_consideration"
      t.text "qualitygoals_evaluate"
      t.text "total_report"

      t.timestamps
    end
  end
end
