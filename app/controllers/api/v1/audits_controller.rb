class Api::V1::AuditsController < ApplicationController

  # 一覧取得（プロジェクトIDと種別（plan or report）を指定）
  def index_by_project
    audits = Audit.
              joins("LEFT OUTER JOIN employees AS auditemps ON auditemps.id=auditor_id LEFT OUTER JOIN employees AS acptemps ON acptemps.id=accept_id")
              .select("audits.*, auditemps.name as auditor_name, acptemps.name as accept_name")
              .where(project_id: params[:project_id], kinds: params[:kinds])
              .order(:number)
    render json: { status: 200, audits: audits }
  end

#  def create
#    audit = Audit.new(audit_params)
#    if audit.save then
#      render json: { status: 200, message: "Addition Success" }
#    else
#      render json: { status: 500, message: "Addition Error" }
#    end
#  end

  # 更新処理（プロジェクトID指定）
  # プロジェクト計画書の状態も併せて更新する。
  # プロジェクト計画書への状態更新が承認の場合は、変更記録に「初版」を登録する。
  def update
    ActiveRecord::Base.transaction do

      audit_num = 0
      audit_params[:audits].map do |audit_param|
        if audit_param[:del].blank? then
          audit_num += 1
          audit = Audit.find_or_initialize_by(id: audit_param[:id])
          audit.project_id = params[:id]
          audit.kinds = audit_param[:kinds]
          audit.number = audit_num
          audit.auditor_id = audit_param[:auditor_id]
          audit.audit_date = audit_param[:audit_date]
          audit.title = audit_param[:title]
          audit.contents = audit_param[:contents]
          audit.result = audit_param[:result]
          audit.accept_id = audit_param[:accept_id]
          audit.accept_date = audit_param[:accept_date]
          audit.save!
        else
          if audit_param[:id].present? then
            audit = Audit.find(audit_param[:id])
            audit.destroy!
          end
        end
      end

      if audit_params[:prj].present? then
        prj_param = audit_params[:prj]
        if prj_param[:status].present? then
          prj = Project.find(params[:id])
          prj.status = prj_param[:status]
          prj.save!

          if prj_param[:status] == "PJ推進中" then
            changelog = Changelog.new
            changelog.project_id = params[:id]
            changelog.changer_id = prj.make_id
            changelog.change_date = Date.today
            changelog.contents = "初版（監査承認）"
            changelog.save!
          end
        end
      end

    end

    render json: { status: 200, message: "Update Success!" }

  rescue => e

    render json: { status: 500, message: "Update Error"}

  end

  private
  def audit_params
    params.permit(prj: [:status],
                  audits: [:id, :project_id, :kinds, :number, 
                            :auditor_id, :audit_date, :title, :contents, 
                            :result, :accept_id, :accept_date, :del]
                )
  end
end
