class Api::V1::WorkreportsController < ApplicationController
  def index_by_daily
    workreports = Workreport
                    .joins("LEFT OUTER JOIN projects AS prjs ON prjs.id=project_id")
                    .joins("LEFT OUTER JOIN phases ON phases.id=phase_id")
                    .joins("LEFT OUTER JOIN tasks ON tasks.id=task_id")
                    .select("prjs.name AS project_name, phases.name AS phase_name, tasks.name AS task_name, workreports.*")
                    .where(dailyreport_id: params[:id]).order(:number)
    render json: { status: 200, workreports: workreports }
  end
    
  def update
    ActiveRecord::Base.transaction do

      # 作業日報更新
      num = 0
      work_params[:workreports].map do |work_param|
        if work_param[:del].blank? then
          num += 1
          work = Workreport.find_or_initialize_by(id: work_param[:id])
          work.dailyreport_id = params[:id]
          work.number = num
          work.project_id = work_param[:project_id]
          work.phase_id = work_param[:phase_id]
          work.task_id = work_param[:task_id]
          work.hour = work_param[:hour]
          work.minute = work_param[:minute]
          work.over_h = work_param[:over_h]
          work.over_m = work_param[:over_m]
          work.comments = work_param[:comments]
          work.save!
        else
          if work_param[:id].present? then
            work = Workreport.find(work_param[:id])
            work.destroy!
          end
        end
      end

      # 勤務日報更新
      daily_param = work_params[:dailyreport]
      daily = Dailyreport.find(params[:id])
      daily.work_prescribed_h = daily_param[:work_prescribed_h]
      daily.work_prescribed_m = daily_param[:work_prescribed_m]
      daily.work_over_h = daily_param[:work_over_h]
      daily.work_over_m = daily_param[:work_over_m]
      daily.save!

    end

    render json: { status: 200, message: "Update Success!" }

  rescue => e

    render json: { status: 500, message: "Update Error"}

  end

  private
  def work_params
#    params.permit(workreports: [:id, :dailyreport_id, :number, :project_id, :phase_id, :task_id,
#                                  :hour, :minute, :over_h, :over_m, :comments, :del])
    params.permit(workreports: [:id, :dailyreport_id, :number, :project_id, :phase_id, :task_id,
                                :hour, :minute, :over_h, :over_m, :comments, :del],
                  dailyreport: [:work_prescribed_h, :work_prescribed_m, :work_over_h, :work_over_m])
  end

end
