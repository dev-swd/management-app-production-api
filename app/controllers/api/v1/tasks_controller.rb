class Api::V1::TasksController < ApplicationController

  # タスクToDo取得（empId指定）
  def index_todo
    # 対象＝指定empIDが担当になっていて、開始日経過
    tasks = Task
            .joins(phase: :project)
            .select("tasks.*, phases.name as phase_name, phases.project_id as prj_id, projects.number as prj_number, projects.name as prj_name")
            .where(worker_id: params[:id])
            .where("tasks.planned_periodfr <= ?", Date.today)
            .order(:planned_periodto, :planned_periodfr)
    render json: { status: 200, tasks: tasks }
  end

  # PhaseIdを条件とした一覧取得（工程情報を別途添付）
  def index_by_phase
    phase = Phase
            .joins("LEFT OUTER JOIN projects AS prj ON prj.id=project_id")
            .select("prj.number as prj_number, prj.name as prj_name, phases.*")
            .find(params[:id])
    tasks = Task
            .joins(:phase)
            .joins("LEFT OUTER JOIN employees AS emp ON emp.id=worker_id")
            .select("tasks.*, emp.name as worker_name, phases.name as phase_name")
            .where(phase_id: params[:id])
            .order(:number)
    render json: { status: 200, phase: phase, tasks: tasks }
  end

  # PhaseIdを条件とした一覧取得（工程情報を別途添付／外注を対象外）
  def index_by_phase_without_outsourcing
    phase = Phase
            .joins("LEFT OUTER JOIN projects AS prj ON prj.id=project_id")
            .select("prj.number as prj_number, prj.name as prj_name, phases.*")
            .find(params[:id])
    tasks = Task
            .joins(:phase)
            .joins("LEFT OUTER JOIN employees AS emp ON emp.id=worker_id")
            .select("tasks.*, emp.name as worker_name, phases.name as phase_name")
            .where(phase_id: params[:id])
            .where(outsourcing: false)
            .order(:number)
    render json: { status: 200, phase: phase, tasks: tasks }
  end

  # タスク作成時の登録処理（追加 or 更新 or 削除）
  def update_for_planned
    ActiveRecord::Base.transaction do

      task_num = 0
      task_params[:tasks].map do |task_param|
        if task_param[:del].blank? then
          task_num += 1
          task = Task.find_or_initialize_by(id: task_param[:id])
          task.phase_id = params[:id]
          task.number = task_num
          task.name = task_param[:name]
          task.worker_id = task_param[:worker_id]
          task.outsourcing = task_param[:outsourcing]
          task.planned_workload = task_param[:planned_workload]
          task.planned_periodfr = task_param[:planned_periodfr]
          task.planned_periodto = task_param[:planned_periodto]
          task.tag = task_param[:tag]
          task.save!
        else
          if task_param[:id].present? then
            task = Task.find(task_param[:id])
            task.destroy!
          end
        end
      end
    end
    
    render json: { status:200, message: "Update Success!"}

  rescue => e

    render json: { status:500, message: "Update Error"}

  end

# ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑　再確認済み


  # ProjectIdを条件とした一覧取得（工程名付）
  def index_by_project
    tasks = Task
            .joins(phase: :project)
            .joins("LEFT OUTER JOIN employees AS emp ON emp.id=worker_id")
            .select("tasks.*, emp.name as worker_name, phases.name as phase_name")
            .where(projects: { id: params[:id]})
            .order(:number)
    render json: { status: 200, tasks: tasks }
  end

  # タスク実績日付更新
  def update_for_actualdate
    ActiveRecord::Base.transaction do

      task_params[:tasks].map do |task_param|
        task = Task.find(task_param[:id])
        task.actual_periodfr = task_param[:actual_periodfr]
        task.actual_periodto = task_param[:actual_periodto]
        task.save!
      end

    end

    render json: { status:200, message: "Update Success!"}

  rescue => e

    render json: { status:500, message: "Update Error"}

  end

  # タスク別予実データ取得
  def index_plan_and_actual
    tasks = Taskcopy.joins(:taskactual)
                    .where(progressreport_id: params[:prog_id])
                    .where(phase_id: params[:phase_id])
                    .where(outsourcing: false)
                    .select("taskcopies.*, taskactuals.*")
                    .order(:number)
    render json: { status: 200, tasks: tasks }
  end

  private
  def task_params
    params.permit(tasks: [:id, :name, :worker_id, :outsourcing, 
                          :planned_workload, :planned_periodfr, :planned_periodto,
                          :actual_workload, :actual_periodfr, :actual_periodto, :tag, :del])
  end
end
