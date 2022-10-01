class Api::V1::PhasesController < ApplicationController

  # 一覧取得（プロジェクトID指定）
  # 工程情報の一覧とプロジェクト情報の作業費、作業工数、外注費、外注工数を取得
  def index_by_project
    prj = Project.find(params[:id])
    phases = Phase
              .where(project_id: params[:id])
              .order(:number)
    render json: { status: 200, prj: prj, phases: phases }
  end

  # 工程情報更新（工程IDをパラメータ指定）
  def update
    ActiveRecord::Base.transaction do

      phases_params[:phases].map do |phase_param|
        phase = Phase.find(phase_param[:id])
        phase.planned_cost = phase_param[:planned_cost]
        phase.planned_workload = phase_param[:planned_workload]
        phase.planned_outsourcing_cost = phase_param[:planned_outsourcing_cost]
        phase.planned_outsourcing_workload = phase_param[:planned_outsourcing_workload]
        phase.save!
      end

    end

    render json: { status: 200, message: "Update Success!" }

  rescue => e

    render json: { status: 500, message: "Update Error"}

  end
  
  # 工程別予実データ取得
  def index_plan_and_actual
    phases = Phasecopy.joins(:phaseactual)
                      .where(progressreport_id: params[:id])
                      .select("phasecopies.*, phaseactuals.*")
                      .order(:number)
    render json: { status: 200, phases: phases }
  end

  private
  def phases_params
    params.permit(phases: [:id, :project_id, :number, :name, 
                  :planned_periodfr, :planned_periodto, :actual_periodfr, :actual_periodto, 
                  :deliverables, :criteria, :review_count,
                  :planned_cost, :planned_workload, :planned_outsourcing_cost, :planned_outsourcing_workload,
                  :actual_cost, :actual_workload, :actual_outsourcing_cost, :actual_outsourcing_workload,
                  :ship_number, :accept_comp_date])
  end
#  def index
#    render json: Phase.all.order(:number)
#  end

#  def show
#    render json: Phase.find(params[:id])
#  end
    
#  def create
#    ph = Phase.new(ph_params)
#    if ph.save
#      render json: ph
#    else
#      render json: { status: 500, messages: ph.errors }
#    end
#  end

#  def update
#    ph = Phase.find(params[:id])
#    if ph.update(ph_params)
#      render json: ph
#    else
#      render json: {status: 500, messages: ph.errors }
#    end
#  end

#  def destroy
#    ph = Phase.find(params[:id])
#    ph.destroy
#    render json: ph
#  end

#  private
#  def ph_params
#    params.require(:phase).permit(:project_id, :number, :name, :deliverables, :criteria, 
#                                :planned_periodfr, :planned_periodto, :actual_periodfr, :actual_periodto, 
#                                :planned_cost, :planned_workload, :actual_cost, :actual_workload,
#                                :ship_number, :accept_comp_date)
#  end
end
