class Api::V1::EvmsController < ApplicationController
  # 条件指定でのEVM一覧取得 
  # 引数：prog=進捗レポートID
  # 引数：level=project or phase
  # 引数：phase=phase_id(level=phaseの場合のみ必要)
  def index_by_conditional
    if params[:level]=="project" then
      evms = Evm.where(progressreport_id: params[:prog])
                .where(level: params[:level])
                .order(:date_to)
      render json: { status: 200, evms: evms }
    else
      evms = Evm.where(progressreport_id: params[:prog])
                .where(level: params[:level])
                .where(phase_id: params[:phase])
                .order(:date_to)
      render json: { status: 200, evms: evms }
    end
  end

end
