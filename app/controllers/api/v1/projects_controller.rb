class Api::V1::ProjectsController < ApplicationController

  # プロジェクトToDo取得（empId指定）
  def index_todo
    # 対象＝PLになっていて、計画未提出、計画書差戻、PJ推進中且つ予定期間（至）経過、完了報告書差戻
    prjs = Project
            .where(pl_id: params[:id])
            .where("(status = '計画未提出') or (status = '計画書差戻') or (status= 'PJ推進中' and development_period_to <= ?) or (status = '完了報告書差戻')", Date.today)
    render json: { status: 200, prjs: prjs }
  end

  # 内部監査ToDo取得
  def index_audit_todo
    # 対象＝計画書監査中、完了報告書監査中
    prjs = Project
            .where(status: ["計画書監査中", "完了報告書監査中"])
    render json: { status: 200, prjs: prjs }
  end

  # PL一覧
  def index_pl

    if params[:not_project].present? then
      # プロジェクト／プトジェクト外の指定あり
      if params[:not_project].downcase=="true" then
        not_project = true
      else
        not_project = false
      end
      pls = Project
            .joins("INNER JOIN employees AS plemp ON plemp.id=pl_id")
            .where(not_project: not_project)
            .group(:pl_id)
            .group("pl_number, pl_name")
            .select("projects.pl_id, plemp.number as pl_number, plemp.name as pl_name")
            .order("plemp.number")
      render json: { status: 200, pls: pls }
    else      
      pls = Project
            .joins("INNER JOIN employees AS plemp ON plemp.id=pl_id")
            .group(:pl_id)
            .group("pl_number, pl_name")
            .select("projects.pl_id, plemp.number as pl_number, plemp.name as pl_name")
            .order("plemp.number")
      render json: { status: 200, pls: pls }
    end
  end
  
  # 条件指定でのプロジェクト一覧 
  def index_by_conditional
    where = ""

    # プロジェクト／プロジェクト外
    if params[:not_project].present? then
      if params[:not_project].downcase=="true" then
        # プロジェクト外
        where = "projects.not_project=true "  
      else
        # プロジェクト
        where = "projects.not_project=false "  
      end
    end

    # 状態の条件指定あり
    if params[:status].present? then
      if where.present? then
        where += "and  "
      end      
      if params[:status]=="*" then
        # すべての場合は条件なし
      elsif params[:status]=="-" then
        where += "projects.status<>'完了' "
      else
        where += "projects.status='" + params[:status] + "' "
      end
    end

    # PLの条件指定あり
    if params[:pl].present? then
      if where.present? then
        where += "and projects.pl_id=" + params[:pl] + " "
      else
        where += "projects.pl_id=" + params[:pl] + " "
      end
    end

    # 並び順指定
    if params[:order].present? then
      if params[:desc]=="true" then
        order = "projects." + params[:order] + " desc"
      else
        order = "projects." + params[:order]
      end
    end

    projects = Project
                .joins("LEFT OUTER JOIN employees AS plemp ON plemp.id=pl_id")
                .select("projects.*, plemp.name as pl_name")
                .where(where)
                .order(order)

    render json: { status: 200, projects: projects }
    
  end

  # プロジェクト新規登録
  def create
    prj = Project.new(prj_params[:prj])
    if prj.save then
      render json: { status:200, message: "Insert Success!", prj: prj }
    else
      render json: { status:500, message: "Insert Error"}
    end
  end

  # プロジェクト削除（ID指定）
  def destroy
    ActiveRecord::Base.transaction do
      prj = Project.find(params[:id])
      prj.destroy!
    end
    render json: { status:200, message: "Delete Success!" }
  rescue => e
    render json: { status:500, message: "Delete Error"}
  end

  # プロジェクト情報取得（プロジェクトID指定／工程、リスク、品質目標、メンバーも取得）
  def show
    project = Project
              .joins("LEFT OUTER JOIN employees AS aemps ON aemps.id=approval LEFT OUTER JOIN employees AS memps ON memps.id=make_id LEFT OUTER JOIN employees AS uemps ON uemps.id=update_id LEFT OUTER JOIN employees AS plemp ON plemp.id=pl_id")
              .select("projects.*, aemps.name as approval_name, memps.name as make_name, uemps.name as update_name, plemp.name as pl_name")
              .find(params[:id])
    phases = Phase.where(project_id: params[:id]).order(:number)
    risks = Risk.where(project_id: params[:id]).order(:number)
    qualitygoals = Qualitygoal.where(project_id: params[:id]).order(:number)
    members = Member
              .joins("LEFT OUTER JOIN employees AS emps ON emps.id=member_id")
              .select("members.*, emps.name as member_name")
              .where(project_id: params[:id])
              .where(level: "emp")
              .order(:number)

    render json: { status: 200, prj: project, phases: phases, risks: risks, goals: qualitygoals, mems: members }
  end

  # プロジェクト更新（プロジェクトID指定／工程、リスク、品質目標、メンバーも更新）
  def update

    ActiveRecord::Base.transaction do

      prj = Project.find(params[:id])
      prj_param = prj_params[:prj]
      prj.status = prj_param[:status]
      prj.approval = prj_param[:approval]
      prj.approval_date = prj_param[:approval_date]
      prj.pl_id = prj_param[:pl_id]
      prj.number = prj_param[:number]
      prj.name = prj_param[:name]
      prj.make_date = prj_param[:make_date]
      prj.make_id = prj_param[:make_id]
      prj.update_date = prj_param[:update_date]
      prj.update_id = prj_param[:update_id]
      prj.company_name = prj_param[:company_name]
      prj.department_name = prj_param[:department_name]
      prj.personincharge_name = prj_param[:personincharge_name]
      prj.phone = prj_param[:phone]
      prj.fax = prj_param[:fax]
      prj.email = prj_param[:email]
      prj.development_period_fr = prj_param[:development_period_fr]
      prj.development_period_to = prj_param[:development_period_to]
      prj.scheduled_to_be_completed = prj_param[:scheduled_to_be_completed]
      prj.system_overview = prj_param[:system_overview]
      prj.development_environment = prj_param[:development_environment]
      prj.order_amount = prj_param[:order_amount]
      prj.planned_work_cost = prj_param[:planned_work_cost]
      prj.planned_workload = prj_param[:planned_workload]
      prj.planned_purchasing_cost = prj_param[:planned_purchasing_cost]
      prj.planned_outsourcing_cost = prj_param[:planned_outsourcing_cost]
      prj.planned_outsourcing_workload = prj_param[:planned_outsourcing_workload]
      prj.planned_expenses_cost = prj_param[:planned_expenses_cost]
      prj.gross_profit = prj_param[:gross_profit]
      prj.work_place_kbn = prj_param[:work_place_kbn]
      prj.work_place = prj_param[:work_place]
      prj.customer_property_kbn = prj_param[:customer_property_kbn]
      prj.customer_property = prj_param[:customer_property]
      prj.customer_environment = prj_param[:customer_environment]
      prj.purchasing_goods_kbn = prj_param[:purchasing_goods_kbn]
      prj.purchasing_goods = prj_param[:purchasing_goods]
      prj.outsourcing_kbn = prj_param[:outsourcing_kbn]
      prj.outsourcing = prj_param[:outsourcing]
      prj.customer_requirement_kbn = prj_param[:customer_requirement_kbn]
      prj.customer_requirement = prj_param[:customer_requirement]
      prj.remarks = prj_param[:remarks]
      prj.save!
      
      prj_params[:phases].map do |phase_param|
        if phase_param[:del].blank? then
          phase = Phase.find_or_initialize_by(id: phase_param[:id])
          phase.project_id = params[:id]
          phase.number = phase_param[:number]
          phase.name = phase_param[:name]
          phase.planned_periodfr = phase_param[:planned_periodfr]
          phase.planned_periodto = phase_param[:planned_periodto]
          phase.deliverables = phase_param[:deliverables]
          phase.criteria = phase_param[:criteria]
          phase.save!
        else
          if phase_param[:id].blank? then
          else
            phase = Phase.find(phase_param[:id])
            phase.destroy!
          end
        end
      end

      risk_num = 0
      prj_params[:risks].map do |risk_param|
        if risk_param[:del].blank? then
          risk_num += 1
          risk = Risk.find_or_initialize_by(id: risk_param[:id])
          risk.project_id = params[:id]
          risk.number = risk_num
          risk.contents = risk_param[:contents]
          risk.save!
        else
          if risk_param[:id].blank? then
          else
            risk = Risk.find(risk_param[:id])
            risk.destroy!
          end
        end
      end

      goal_num = 0
      prj_params[:goals].map do |goal_param|
        if goal_param[:del].blank? then
          goal_num += 1
          goal = Qualitygoal.find_or_initialize_by(id: goal_param[:id])
          goal.project_id = params[:id]
          goal.number = goal_num
          goal.contents = goal_param[:contents]
          goal.save!
        else
          if goal_param[:id].blank? then
          else
            goal = Qualitygoal.find(goal_param[:id])
            goal.destroy!
          end
        end
      end

      mem_num = 0
      prj_params[:mems].map do |mem_param|
        if mem_param[:del].blank? then
          mem_num += 1
          mem = Member.find_or_initialize_by(id: mem_param[:id])
          mem.project_id = params[:id]
          mem.number = mem_num
          mem.level = mem_param[:level]
          mem.member_id = mem_param[:member_id]
          mem.save!
        else
          if mem_param[:id].present? then
            mem = Member.find(mem_param[:id])
            mem.destroy!
          end
        end
      end

      if prj_params[:log].present? then
        log_param = prj_params[:log]
        if log_param[:changer_id].present? then
          log = Changelog.new()
          log.project_id = params[:id]
          log.changer_id = log_param[:changer_id]
          log.change_date = log_param[:change_date]
          log.contents = log_param[:contents]
          log.save!
        end
      end
      
    end

    render json: { status: 200, message: "Update Success!" }

  rescue => e

    render json: { status: 500, message: "Update Error"}

  end

  # 一覧取得（社員ID、対象日付）
  # パラメータ指定の社員が参画するプロジェクトで、パラメータ指定の日付が開発期間内の一覧
  def index_by_member
    projects = Project
                .joins(:members)
                .select("projects.id, projects.number, projects.name")
                .where("development_period_fr <= ? and development_period_to >= ?", params[:thisDate], params[:thisDate])
                .where("(members.level='emp' and members.member_id=?) or (members.level='div' and members.member_id=?) or (members.level='dep' and members.member_id=?)", params[:emp_id], params[:div_id], params[:dep_id])
                .order(:number)
    render json: { status: 200, projects: projects }
  end

  # 一覧取得（社員ID）
  # パラメータ指定の社員が参画する推進中のプロジェクト一覧
  def index_by_member_running
    projects = Project
                .joins("LEFT OUTER JOIN employees AS plemp ON plemp.id=pl_id")
                .joins(:members)
                .select("projects.*, plemp.name as pl_name")
                .where(members: { level: 'emp', member_id: params[:id] })
                .where("(status= 'PJ推進中') or (status = '完了報告書差戻')")
                .order(:number)
    render json: { status: 200, projects: projects }
  end

  # プロジェクト外タスクグループ登録
  def create_no_project
    ActiveRecord::Base.transaction do

      prj_param = prj_params[:prj]

      # プロジェクト情報
      prj = Project.new()
      prj.status = "管理対象外"
      prj.pl_id = prj_param[:pl_id]
      prj.number = prj_param[:number]
      prj.name = prj_param[:name]
      prj.make_date = Date.today
      prj.make_id = prj_param[:pl_id]
      prj.update_date = Date.today
      prj.update_id = prj_param[:pl_id]
      prj.development_period_fr = prj_param[:development_period_fr]
      prj.development_period_to = prj_param[:development_period_to]
      prj.remarks = prj_param[:remarks]
      prj.not_project = true
      prj.save!

      # 工程情報
      phase = Phase.new()
      phase.project_id = prj.id
      phase.number = ""
      phase.name = ""
      phase.planned_periodfr = prj_param[:development_period_fr]
      phase.planned_periodto = prj_param[:development_period_to]
      phase.save!

      # タスク情報
      task_num = 0
      prj_params[:tasks].map do |task_param|
        if task_param[:del].blank? then
          task_num += 1
          task = Task.new()
          task.phase_id = phase.id
          task.number = task_num
          task.name = task_param[:name]
          task.planned_periodfr = prj_param[:development_period_fr]
          task.planned_periodto = prj_param[:development_period_to]
          task.save!
        end
      end

      # メンバー情報
      mem_num = 0
      prj_params[:mems].map do |mem_param|
        if mem_param[:del].blank? then
          mem_num += 1
          mem = Member.new()
          mem.project_id = prj.id
          mem.number = mem_num
          mem.level = mem_param[:level]
          mem.member_id = mem_param[:member_id]
          mem.save!
        end
      end
    end

    render json: { status:200, message: "Create Success!"}

  rescue => e

    render json: { status:500, message: "Create Error"}

  end

  # プロジェクト外タスクグループ更新
  def update_no_project
    ActiveRecord::Base.transaction do

      # プロジェクト情報
      prj = Project.find(params[:id])
      prj_param = prj_params[:prj]
      prj.update_date = Date.today
      prj.update_id = prj_param[:pl_id]
      prj.development_period_fr = prj_param[:development_period_fr]
      prj.development_period_to = prj_param[:development_period_to]
      prj.remarks = prj_param[:remarks]
      prj.save!

      # タスク情報
      task_num = 0
      prj_params[:tasks].map do |task_param|
        if task_param[:del].blank? then
          task_num += 1
          task = Task.find_or_initialize_by(id: task_param[:id])
          task.phase_id = task_param[:phase_id]
          task.number = task_num
          task.name = task_param[:name]
          task.planned_periodfr = prj_param[:development_period_fr]
          task.planned_periodto = prj_param[:development_period_to]
          task.save!
        else
          if task_param[:id].present? then
            task = Task.find(task_param[:id])
            task.destroy!
          end
        end
      end

      # メンバー情報
      mem_num = 0
      prj_params[:mems].map do |mem_param|
        if mem_param[:del].blank? then
          mem_num += 1
          mem = Member.find_or_initialize_by(id: mem_param[:id])
          mem.project_id = params[:id]
          mem.number = mem_num
          mem.level = mem_param[:level]
          mem.member_id = mem_param[:member_id]
          mem.save!
        else
          if mem_param[:id].present? then
            mem = Member.find(mem_param[:id])
            mem.destroy!
          end
        end
      end

    end

    render json: { status:200, message: "Update Success!"}

  rescue => e

    render json: { status:500, message: "Update Error"}

  end

  # プロジェクト外タスクグループ詳細
  def show_no_project
    project = Project
              .joins("LEFT OUTER JOIN employees AS aemps ON aemps.id=approval LEFT OUTER JOIN employees AS memps ON memps.id=make_id LEFT OUTER JOIN employees AS uemps ON uemps.id=update_id LEFT OUTER JOIN employees AS plemp ON plemp.id=pl_id")
              .select("projects.*, aemps.name as approval_name, memps.name as make_name, uemps.name as update_name, plemp.name as pl_name")
              .find(params[:id])
    phase = Phase.find_by(project_id: params[:id])
    tasks = Task
            .joins(:phase)
            .where("phases.project_id = ?", params[:id])
            .order(:number)


    sql = "select members.*, emps.name as member_name from members LEFT OUTER JOIN employees AS emps ON emps.id=member_id where project_id = :project_id and level = 'emp' "
    sql += "union "
    sql += "select members.*, divs.name as member_name from members LEFT OUTER JOIN divisions AS divs ON divs.id=member_id where project_id = :project_id and level = 'div' "
    sql += "union "
    sql += "select members.*, deps.name as member_name from members LEFT OUTER JOIN departments AS deps ON deps.id=member_id where project_id = :project_id and level = 'dep' "
    sql += "order by number "
    mems = Member.find_by_sql([sql, { project_id: params[:id] }])

    render json: { status: 200, project: project, phase: phase, tasks: tasks, mems: mems }
  end
  
# ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑　確認済み

  def index
    render json: Project.joins("LEFT OUTER JOIN employees AS plemp ON plemp.id=pl_id").select("projects.*, plemp.name as pl_name").order(:number)
  end

  private
  def prj_params
    params.permit(prj: [:status, :approval, :approval_date, :pl_id, :number, :name, 
      :make_date, :make_id, :update_date, :update_id, :company_name, :department_name, 
      :personincharge_name, :phone, :fax, :email, :development_period_fr, :development_period_to, 
      :scheduled_to_be_completed, :system_overview, :development_environment, 
      :order_amount, :planned_work_cost, :planned_workload, :planned_purchasing_cost, 
      :planned_outsourcing_cost, :planned_outsourcing_workload, :planned_expenses_cost, :gross_profit, 
      :work_place_kbn, :work_place, :customer_property_kbn, :customer_property, :customer_environment, 
      :purchasing_goods_kbn, :purchasing_goods, :outsourcing_kbn, :outsourcing, 
      :customer_requirement_kbn, :customer_requirement, :remarks, :plan_approval, :plan_approval_date],
      phases: [:id, :project_id, :number, :name, :planned_periodfr, :planned_periodto, :deliverables, :criteria, :del],
      risks: [:id, :project_id, :number, :contents, :del],
      goals: [:id, :project_id, :number, :contents, :del],
      mems: [:id, :project_id, :number, :level, :member_id, :del],
      log: [:changer_id, :change_date, :contents],
      tasks: [:id, :phase_id, :name, :del],
    )
  end
end
