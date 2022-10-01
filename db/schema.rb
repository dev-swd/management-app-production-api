# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2022_09_26_140022) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "approvalauths", force: :cascade do |t|
    t.bigint "employee_id"
    t.bigint "division_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["division_id"], name: "index_approvalauths_on_division_id"
    t.index ["employee_id"], name: "index_approvalauths_on_employee_id"
  end

  create_table "audits", force: :cascade do |t|
    t.bigint "project_id"
    t.string "kinds"
    t.integer "number"
    t.bigint "auditor_id"
    t.date "audit_date"
    t.string "title"
    t.text "contents"
    t.string "result"
    t.bigint "accept_id"
    t.date "accept_date"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["project_id"], name: "index_audits_on_project_id"
  end

  create_table "changelogs", force: :cascade do |t|
    t.bigint "project_id"
    t.integer "number"
    t.bigint "changer_id"
    t.date "change_date"
    t.text "contents"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["project_id"], name: "index_changelogs_on_project_id"
  end

  create_table "dailyreports", force: :cascade do |t|
    t.bigint "employee_id"
    t.string "ym"
    t.date "date"
    t.string "kbn"
    t.string "kbn_reason"
    t.integer "prescribed_frh"
    t.integer "prescribed_frm"
    t.integer "prescribed_toh"
    t.integer "prescribed_tom"
    t.integer "lunch_frh"
    t.integer "lunch_frm"
    t.integer "lunch_toh"
    t.integer "lunch_tom"
    t.string "over_reason"
    t.integer "over_frh"
    t.integer "over_frm"
    t.integer "over_toh"
    t.integer "over_tom"
    t.integer "rest_frh"
    t.integer "rest_frm"
    t.integer "rest_toh"
    t.integer "rest_tom"
    t.string "late_reason"
    t.integer "late_h"
    t.integer "late_m"
    t.string "goout_reason"
    t.integer "goout_frh"
    t.integer "goout_frm"
    t.integer "goout_toh"
    t.integer "goout_tom"
    t.string "early_reason"
    t.integer "early_h"
    t.integer "early_m"
    t.integer "prescribed_h"
    t.integer "prescribed_m"
    t.integer "over_h"
    t.integer "over_m"
    t.integer "midnight_h"
    t.integer "midnight_m"
    t.integer "work_prescribed_h"
    t.integer "work_prescribed_m"
    t.integer "work_over_h"
    t.integer "work_over_m"
    t.string "status"
    t.bigint "approval_id"
    t.date "approval_date"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["employee_id"], name: "index_dailyreports_on_employee_id"
  end

  create_table "departments", force: :cascade do |t|
    t.string "code"
    t.string "name"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "divisions", force: :cascade do |t|
    t.bigint "department_id"
    t.string "code"
    t.string "name"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["department_id"], name: "index_divisions_on_department_id"
  end

  create_table "employees", force: :cascade do |t|
    t.string "number"
    t.string "name"
    t.string "name2"
    t.date "birthday"
    t.string "address"
    t.string "phone"
    t.date "joining_date"
    t.bigint "division_id"
    t.bigint "devise_id"
    t.string "authority"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "evms", force: :cascade do |t|
    t.bigint "progressreport_id"
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
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["progressreport_id"], name: "index_evms_on_progressreport_id"
  end

  create_table "members", force: :cascade do |t|
    t.bigint "project_id"
    t.string "number"
    t.string "level"
    t.bigint "member_id"
    t.string "tag"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["project_id"], name: "index_members_on_project_id"
  end

  create_table "phaseactuals", force: :cascade do |t|
    t.bigint "progressreport_id"
    t.bigint "phasecopy_id"
    t.date "periodfr"
    t.date "periodto"
    t.bigint "total_cost"
    t.decimal "total_workload", precision: 6, scale: 2
    t.decimal "overtime_workload", precision: 6, scale: 2
    t.decimal "after_total_workload", precision: 6, scale: 2
    t.decimal "after_overtime_workload", precision: 6, scale: 2
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["phasecopy_id"], name: "index_phaseactuals_on_phasecopy_id"
    t.index ["progressreport_id"], name: "index_phaseactuals_on_progressreport_id"
  end

  create_table "phasecopies", force: :cascade do |t|
    t.bigint "progressreport_id"
    t.bigint "phase_id"
    t.string "number"
    t.string "name"
    t.date "planned_periodfr"
    t.date "planned_periodto"
    t.date "actual_periodfr"
    t.date "actual_periodto"
    t.bigint "planned_cost"
    t.decimal "planned_workload", precision: 5, scale: 2
    t.bigint "planned_outsourcing_cost"
    t.decimal "planned_outsourcing_workload", precision: 5, scale: 2
    t.bigint "actual_cost"
    t.decimal "actual_workload", precision: 5, scale: 2
    t.bigint "actual_outsourcing_cost"
    t.decimal "actual_outsourcing_workload", precision: 5, scale: 2
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["progressreport_id"], name: "index_phasecopies_on_progressreport_id"
  end

  create_table "phases", force: :cascade do |t|
    t.bigint "project_id"
    t.string "number"
    t.string "name"
    t.date "planned_periodfr"
    t.date "planned_periodto"
    t.date "actual_periodfr"
    t.date "actual_periodto"
    t.text "deliverables"
    t.text "criteria"
    t.integer "review_count"
    t.bigint "planned_cost"
    t.decimal "planned_workload", precision: 5, scale: 2
    t.bigint "planned_outsourcing_cost"
    t.decimal "planned_outsourcing_workload", precision: 5, scale: 2
    t.bigint "actual_cost"
    t.decimal "actual_workload", precision: 5, scale: 2
    t.bigint "actual_outsourcing_cost"
    t.decimal "actual_outsourcing_workload", precision: 5, scale: 2
    t.string "ship_number"
    t.date "accept_comp_date"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["project_id"], name: "index_phases_on_project_id"
  end

  create_table "progressreports", force: :cascade do |t|
    t.bigint "project_id"
    t.bigint "make_id"
    t.string "totaling_day"
    t.string "outsourcing"
    t.date "development_period_fr"
    t.date "development_period_to"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["project_id"], name: "index_progressreports_on_project_id"
  end

  create_table "projects", force: :cascade do |t|
    t.string "status"
    t.bigint "approval"
    t.date "approval_date"
    t.bigint "pl_id"
    t.string "number"
    t.string "name"
    t.date "make_date"
    t.bigint "make_id"
    t.date "update_date"
    t.bigint "update_id"
    t.string "company_name"
    t.string "department_name"
    t.string "personincharge_name"
    t.string "phone"
    t.string "fax"
    t.string "email"
    t.date "development_period_fr"
    t.date "development_period_to"
    t.date "scheduled_to_be_completed"
    t.text "system_overview"
    t.text "development_environment"
    t.bigint "order_amount"
    t.bigint "planned_work_cost"
    t.decimal "planned_workload", precision: 5, scale: 2
    t.bigint "planned_purchasing_cost"
    t.bigint "planned_outsourcing_cost"
    t.decimal "planned_outsourcing_workload", precision: 5, scale: 2
    t.bigint "planned_expenses_cost"
    t.bigint "gross_profit"
    t.string "work_place_kbn"
    t.string "work_place"
    t.string "customer_property_kbn"
    t.string "customer_property"
    t.string "customer_environment"
    t.string "purchasing_goods_kbn"
    t.string "purchasing_goods"
    t.string "outsourcing_kbn"
    t.string "outsourcing"
    t.string "customer_requirement_kbn"
    t.string "customer_requirement"
    t.text "remarks"
    t.string "plan_approval"
    t.date "plan_approval_date"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.boolean "not_project", default: false, null: false
  end

  create_table "qualitygoals", force: :cascade do |t|
    t.bigint "project_id"
    t.string "number"
    t.text "contents"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["project_id"], name: "index_qualitygoals_on_project_id"
  end

  create_table "reports", force: :cascade do |t|
    t.bigint "project_id"
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
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["project_id"], name: "index_reports_on_project_id"
  end

  create_table "risks", force: :cascade do |t|
    t.bigint "project_id"
    t.string "number"
    t.text "contents"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["project_id"], name: "index_risks_on_project_id"
  end

  create_table "taskactuals", force: :cascade do |t|
    t.bigint "progressreport_id"
    t.bigint "taskcopy_id"
    t.decimal "total_workload", precision: 6, scale: 2
    t.decimal "overtime_workload", precision: 6, scale: 2
    t.decimal "after_total_workload", precision: 6, scale: 2
    t.decimal "after_overtime_workload", precision: 6, scale: 2
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["progressreport_id"], name: "index_taskactuals_on_progressreport_id"
    t.index ["taskcopy_id"], name: "index_taskactuals_on_taskcopy_id"
  end

  create_table "taskcopies", force: :cascade do |t|
    t.bigint "progressreport_id"
    t.bigint "number"
    t.bigint "phase_id"
    t.bigint "task_id"
    t.string "task_name"
    t.string "worker_name"
    t.boolean "outsourcing", default: false, null: false
    t.decimal "planned_workload", precision: 6, scale: 2
    t.date "planned_periodfr"
    t.date "planned_periodto"
    t.decimal "actual_workload", precision: 6, scale: 2
    t.date "actual_periodfr"
    t.date "actual_periodto"
    t.string "tag"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["progressreport_id"], name: "index_taskcopies_on_progressreport_id"
  end

  create_table "tasks", force: :cascade do |t|
    t.bigint "phase_id"
    t.bigint "number"
    t.string "name"
    t.bigint "worker_id"
    t.boolean "outsourcing", default: false, null: false
    t.decimal "planned_workload", precision: 6, scale: 2
    t.date "planned_periodfr"
    t.date "planned_periodto"
    t.decimal "actual_workload", precision: 6, scale: 2
    t.date "actual_periodfr"
    t.date "actual_periodto"
    t.string "tag"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["phase_id"], name: "index_tasks_on_phase_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "provider", default: "email", null: false
    t.string "uid", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.boolean "allow_password_change", default: false
    t.datetime "remember_created_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.string "name"
    t.string "nickname"
    t.string "image"
    t.string "email"
    t.json "tokens"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["uid", "provider"], name: "index_users_on_uid_and_provider", unique: true
  end

  create_table "workreports", force: :cascade do |t|
    t.bigint "dailyreport_id"
    t.integer "number"
    t.bigint "project_id"
    t.bigint "phase_id"
    t.bigint "task_id"
    t.integer "hour"
    t.integer "minute"
    t.integer "over_h"
    t.integer "over_m"
    t.string "comments"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["dailyreport_id"], name: "index_workreports_on_dailyreport_id"
  end

  add_foreign_key "approvalauths", "divisions"
  add_foreign_key "approvalauths", "employees"
  add_foreign_key "audits", "projects"
  add_foreign_key "changelogs", "projects"
  add_foreign_key "dailyreports", "employees"
  add_foreign_key "divisions", "departments"
  add_foreign_key "evms", "progressreports"
  add_foreign_key "members", "projects"
  add_foreign_key "phaseactuals", "phasecopies"
  add_foreign_key "phaseactuals", "progressreports"
  add_foreign_key "phasecopies", "progressreports"
  add_foreign_key "phases", "projects"
  add_foreign_key "progressreports", "projects"
  add_foreign_key "qualitygoals", "projects"
  add_foreign_key "reports", "projects"
  add_foreign_key "risks", "projects"
  add_foreign_key "taskactuals", "progressreports"
  add_foreign_key "taskactuals", "taskcopies"
  add_foreign_key "taskcopies", "progressreports"
  add_foreign_key "tasks", "phases"
  add_foreign_key "workreports", "dailyreports"
end
