class Api::V1::ReportsController < ApplicationController

  # 詳細情報取得（プロジェクトID指定／プロジェクト情報、工程情報、完了報告書情報を取得）
  def show
    project = Project
              .joins("LEFT OUTER JOIN employees AS aemps ON aemps.id=approval LEFT OUTER JOIN employees AS memps ON memps.id=make_id LEFT OUTER JOIN employees AS uemps ON uemps.id=update_id LEFT OUTER JOIN employees AS plemp ON plemp.id=pl_id")
              .select("projects.*, aemps.name as approval_name, memps.name as make_name, uemps.name as update_name, plemp.name as pl_name")
              .find(params[:id])
    phases = Phase
              .where(project_id: params[:id])
              .order(:number)
    report = Report
              .joins("LEFT OUTER JOIN employees AS memps ON memps.id=make_id")
              .select("reports.*, memps.name as make_name")
              .find_by(project_id: params[:id])
    
    render json: { status: 200, prj: project, phases: phases, rep: report }
  end

  # 更新（プロジェクトID指定で、完了報告書、工程、計画書の状態を更新する）
  def update

    ActiveRecord::Base.transaction do

      prj_param = rep_params[:prj]
      rep_param = rep_params[:rep]
      rep = Report.find_or_initialize_by(id: rep_param[:id])
      rep.project_id = params[:id]
      rep.approval = rep_param[:approval]
      rep.approval_date = rep_param[:approval_date]
      rep.make_date = rep_param[:make_date]
      rep.make_id = rep_param[:make_id]
      rep.delivery_date = rep_param[:delivery_date]
      rep.actual_work_cost = rep_param[:actual_work_cost]
      rep.actual_workload = rep_param[:actual_workload]
      rep.actual_purchasing_cost = rep_param[:actual_purchasing_cost]
      rep.actual_outsourcing_cost = rep_param[:actual_outsourcing_cost]
      rep.actual_outsourcing_workload = rep_param[:actual_outsourcing_workload]
      rep.actual_expenses_cost = rep_param[:actual_expenses_cost]
      rep.gross_profit = rep_param[:gross_profit]
      rep.customer_property_accept_result = rep_param[:customer_property_accept_result]
      rep.customer_property_accept_remarks = rep_param[:customer_property_accept_remarks]
      rep.customer_property_used_result = rep_param[:customer_property_used_result]
      rep.customer_property_used_remarks = rep_param[:customer_property_used_remarks]
      rep.purchasing_goods_accept_result = rep_param[:purchasing_goods_accept_result]
      rep.purchasing_goods_accept_remarks = rep_param[:purchasing_goods_accept_remarks]
      rep.outsourcing_evaluate1 = rep_param[:outsourcing_evaluate1]
      rep.outsourcing_evaluate_remarks1 = rep_param[:outsourcing_evaluate_remarks1]
      rep.outsourcing_evaluate2 = rep_param[:outsourcing_evaluate2]
      rep.outsourcing_evaluate_remarks2 = rep_param[:outsourcing_evaluate_remarks2]
      rep.communication_count = rep_param[:communication_count]
      rep.meeting_count = rep_param[:meeting_count]
      rep.phone_count = rep_param[:phone_count]
      rep.mail_count = rep_param[:mail_count]
      rep.fax_count = rep_param[:fax_count]
      rep.design_changes_count = rep_param[:design_changes_count]
      rep.specification_change_count = rep_param[:specification_change_count]
      rep.design_error_count = rep_param[:design_error_count]
      rep.others_count = rep_param[:others_count]
      rep.improvement_count = rep_param[:improvement_count]
      rep.corrective_action_count = rep_param[:corrective_action_count]
      rep.preventive_measures_count = rep_param[:preventive_measures_count]
      rep.project_meeting_count = rep_param[:project_meeting_count]
      rep.statistical_consideration = rep_param[:statistical_consideration]
      rep.qualitygoals_evaluate = rep_param[:qualitygoals_evaluate]
      rep.total_report = rep_param[:total_report]
      rep.save!

      rep_params[:phases].map do |phase_param|
        phase = Phase.find(phase_param[:id])
        phase.review_count = phase_param[:review_count]
        phase.planned_cost = phase_param[:planned_cost]
        phase.actual_cost = phase_param[:actual_cost]
        phase.accept_comp_date = phase_param[:accept_comp_date]
        phase.ship_number = phase_param[:ship_number]
        phase.save!
      end

      if rep_params[:prj].present? then
        prj_param = rep_params[:prj]
        if prj_param[:status]==="完了報告書監査中" then
          prj = Project.find(params[:id])
          prj.status = prj_param[:status]
          prj.save!
        end
      end
    end

    render json: { status: 200, message: "Update Success!" }

  rescue => e
  
    render json: { status: 500, message: "Update Error"}
  
  end

  private
  def rep_params
    params.permit(prj: [:status],
      rep: [:id, :approval, :approval_date, :make_date, :make_id, :delivery_date, 
            :actual_work_cost, :actual_workload, :actual_purchasing_cost, 
            :actual_outsourcing_cost, :actual_outsourcing_workload, :actual_expenses_cost, :gross_profit, 
            :customer_property_accept_result, :customer_property_accept_remarks, 
            :customer_property_used_result, :customer_property_used_remarks, 
            :purchasing_goods_accept_result, :purchasing_goods_accept_remarks, 
            :outsourcing_evaluate1, :outsourcing_evaluate_remarks1, :outsourcing_evaluate2, :outsourcing_evaluate_remarks2, 
            :communication_count, :meeting_count, :phone_count, :mail_count, :fax_count, 
            :design_changes_count, :specification_change_count, :design_error_count, :others_count, 
            :improvement_count, :corrective_action_count, :preventive_measures_count, 
            :project_meeting_count, :statistical_consideration, :qualitygoals_evaluate, :total_report],
      phases: [:id, :review_count, :planned_cost, :actual_cost,:accept_comp_date, :ship_number]
    )
  end
end