class Api::V1::ProgressreportsController < ApplicationController

  #日付条件のテスト
  def show
    prj = Project.find(params[:id])
    weekday = prj.development_period_fr.wday
    since = prj.development_period_fr.days_since(6)

    render json: { status: 200, period_fr: prj.development_period_fr, wday: weekday, since: since }
  end


  # プロジェクトIDを条件とした一覧取得
  def index_by_project
    progs = Progressreport
              .joins("LEFT OUTER JOIN employees AS emp ON emp.id=make_id")
              .select("progressreports.*, emp.name as make_name")
              .where(project_id: params[:id])
              .order(:created_at)
    render json: { status: 200, progs: progs }
  end

  # 進捗集計処理
  # 引数：totaling_day＝0:日曜、1：月曜…、6:土曜
  # 引数：outsourcing(外注の扱い)＝0:そのまま集計、1：除外して集計、2：PVで見做し集計、3：EVで見做し集計
  def create_report
    ActiveRecord::Base.transaction do

      prj = Project.find(params[:id])

      # report作成
      prog = Progressreport.new(project_id: params[:id],
                                make_id: prog_params[:make_id],
                                totaling_day: prog_params[:totaling_day],
                                outsourcing: prog_params[:outsourcing],
                                development_period_fr: prj.development_period_fr,
                                development_period_to: prj.development_period_to)
      prog.save!

      # phaseを凍結
      phases = Phase
              .where(project_id: params[:id])
              .order(:number)
      phases.map do |phase|
        pcopy = Phasecopy.new(progressreport_id: prog.id)
        pcopy.phase_id = phase.id
        pcopy.number = phase.number
        pcopy.name = phase.name
        pcopy.planned_periodfr = phase.planned_periodfr
        pcopy.planned_periodto = phase.planned_periodto
        pcopy.actual_periodfr = phase.actual_periodfr
        pcopy.actual_periodto = phase.actual_periodto
        pcopy.planned_cost = phase.planned_cost
        pcopy.planned_workload = phase.planned_workload
        pcopy.planned_outsourcing_cost = phase.planned_outsourcing_cost
        pcopy.planned_outsourcing_workload = phase.planned_outsourcing_workload
        pcopy.actual_cost = phase.actual_cost
        pcopy.actual_workload = phase.actual_workload
        pcopy.actual_outsourcing_cost = phase.actual_outsourcing_cost
        pcopy.actual_outsourcing_workload = phase.actual_outsourcing_workload
        pcopy.save!
      end

      # tasksを凍結
      tasks = Task
              .joins(:phase)
              .joins("LEFT OUTER JOIN employees AS emp ON emp.id=worker_id")
              .select("tasks.*, emp.name as worker_name")
              .where(phases: { project_id: params[:id]})
              .order(:number)
      tasks.map do |task|
        tcopy = Taskcopy.new(progressreport_id: prog.id)
        tcopy.number = task.number
        tcopy.phase_id = task.phase_id
        tcopy.task_id = task.id
        tcopy.task_name = task.name
        tcopy.worker_name = task.worker_name
        tcopy.outsourcing = task.outsourcing
        tcopy.planned_workload = task.planned_workload
        tcopy.planned_periodfr = task.planned_periodfr
        tcopy.planned_periodto = task.planned_periodto
        tcopy.actual_workload = task.actual_workload
        tcopy.actual_periodfr = task.actual_periodfr
        tcopy.actual_periodto = task.actual_periodto
        tcopy.tag = task.tag
        tcopy.save!
      end

      #*** プロジェクトレベルでのEVM計測 ***
      # BAC(完成時総予算)
      bac = (prj.planned_workload + prj.planned_outsourcing_workload) * 20

      # 計測起点を設定
      period_fr = prj.development_period_fr
      period_to = prj.development_period_fr

      # 開発期間（自）から最初の計測曜日に該当する日付を取得
      if period_fr.wday.to_i != prog_params[:totaling_day].to_i then
        # 開発期間（自）が初回計測日の場合、fr/to同日スタート
        # 開発期間（自）が初回計測日でない場合、翌日から6日間でtoを探索
        for cnt in 1..6 do
          period_to = period_fr.days_since(cnt)
          if period_to.wday.to_i == prog_params[:totaling_day].to_i then
            # 初回計測日であればループを抜ける
            break
          end
        end
      end

      # 開始起点の1週前を計測基点とする
      period_to = period_to.days_ago(7)
      period_fr = period_to.days_ago(6)

      # 開発期間（至）を越えるまで、+7日でループ
      pv_sum = 0
      ev_sum = 0
      ac_sum = 0
      while period_to < prj.development_period_to

        if prog_params[:outsourcing] == "1" then
          # 外注タスクは除外して集計

          #** PV取得 **
          # 該当週に着手のみ
          task_pv1 = Taskcopy
                .where(progressreport_id: prog.id)
                .where("planned_periodfr >= ? and planned_periodfr <= ?", period_fr, period_to)
                .where("planned_periodto > ?", period_to)
                .where(outsourcing: false)
                .select("sum(planned_workload) as pv")
          pv1 = 0
          task_pv1.map do |t|
            pv1 = t.pv.to_f
          end

          # 該当週に着手／完了
          task_pv2 = Taskcopy
                .where(progressreport_id: prog.id)
                .where("planned_periodfr >= ? and planned_periodto <= ?", period_fr, period_to)
                .where(outsourcing: false)
                .select("sum(planned_workload) as pv")
          pv2 = 0
          task_pv2.map do |t|
            pv2 = t.pv.to_f
          end
        
          # 該当週に完了のみ
          task_pv3 = Taskcopy
                .where(progressreport_id: prog.id)
                .where("planned_periodfr < ?", period_fr)
                .where("planned_periodto >= ? and planned_periodto <= ?", period_fr, period_to)
                .where(outsourcing: false)
                .select("sum(planned_workload) as pv")
          pv3 = 0
          task_pv3.map do |t|
            pv3 = t.pv.to_f
          end
        
          #** EV取得 **
          # 該当週に着手のみ
          task_ev1 = Taskcopy
                .where(progressreport_id: prog.id)
                .where("actual_periodfr >= ? and actual_periodfr <= ?", period_fr, period_to)
                .where("actual_periodto > ?", period_to)
                .where(outsourcing: false)
                .select("sum(planned_workload) as ev")
          ev1 = 0
          task_ev1.map do |t|
            ev1 = t.ev.to_f
          end
        
          # 該当週に着手／完了
          task_ev2 = Taskcopy
                .where(progressreport_id: prog.id)
                .where("actual_periodfr >= ? and actual_periodto <= ?", period_fr, period_to)
                .where(outsourcing: false)
                .select("sum(planned_workload) as ev")
          ev2 = 0
          task_ev2.map do |t|
            ev2 = t.ev.to_f
          end
        
          # 該当週に完了のみ
          task_ev3 = Taskcopy
                .where(progressreport_id: prog.id)
                .where("actual_periodfr < ?", period_fr)
                .where("actual_periodto >= ? and actual_periodto <= ?", period_fr, period_to)
                .where(outsourcing: false)
                .select("sum(planned_workload) as ev")
          ev3 = 0
          task_ev3.map do |t|
            ev3 = t.ev.to_f
          end
                
          #** AC取得 **
          # 該当週の日報から集計
          ac_rep = Workreport
                .joins(:dailyreport)
                .where(project_id: params[:id])
                .where("dailyreports.date >= ? and dailyreports.date <= ?", period_fr, period_to)
                .select("sum(workreports.hour) as sum_h,sum(workreports.minute) as sum_m,sum(workreports.over_h) as sum_oh, sum(workreports.over_m) as sum_om")
          ac = 0
          ac_rep.map do |a|
            hours = a.sum_h.to_i + a.sum_oh.to_i
            minutes = a.sum_m.to_i + a.sum_om.to_i
            ac = getWorkload(hours,minutes)
          end
          
        elsif prog_params[:outsourcing] == "2" then
          # 外注タスクはPVで見做し集計

          #** PV取得 **
          # 該当週に着手のみ
          task_pv1 = Taskcopy
                .where(progressreport_id: prog.id)
                .where("planned_periodfr >= ? and planned_periodfr <= ?", period_fr, period_to)
                .where("planned_periodto > ?", period_to)
                .select("sum(planned_workload) as pv")
          pv1 = 0
          task_pv1.map do |t|
            pv1 = t.pv.to_f
          end

          # 該当週に着手／完了
          task_pv2 = Taskcopy
                .where(progressreport_id: prog.id)
                .where("planned_periodfr >= ? and planned_periodto <= ?", period_fr, period_to)
                .select("sum(planned_workload) as pv")
          pv2 = 0
          task_pv2.map do |t|
            pv2 = t.pv.to_f
          end
        
          # 該当週に完了のみ
          task_pv3 = Taskcopy
                .where(progressreport_id: prog.id)
                .where("planned_periodfr < ?", period_fr)
                .where("planned_periodto >= ? and planned_periodto <= ?", period_fr, period_to)
                .select("sum(planned_workload) as pv")
          pv3 = 0
          task_pv3.map do |t|
            pv3 = t.pv.to_f
          end
        
          #** EV取得 **
          # 該当週に着手のみ
          task_ev1 = Taskcopy
                .where(progressreport_id: prog.id)
                .where("actual_periodfr >= ? and actual_periodfr <= ?", period_fr, period_to)
                .where("actual_periodto > ?", period_to)
                .select("sum(planned_workload) as ev")
          ev1 = 0
          task_ev1.map do |t|
            ev1 = t.ev.to_f
          end
        
          # 該当週に着手／完了
          task_ev2 = Taskcopy
                .where(progressreport_id: prog.id)
                .where("actual_periodfr >= ? and actual_periodto <= ?", period_fr, period_to)
                .select("sum(planned_workload) as ev")
          ev2 = 0
          task_ev2.map do |t|
            ev2 = t.ev.to_f
          end
        
          # 該当週に完了のみ
          task_ev3 = Taskcopy
                .where(progressreport_id: prog.id)
                .where("actual_periodfr < ?", period_fr)
                .where("actual_periodto >= ? and actual_periodto <= ?", period_fr, period_to)
                .select("sum(planned_workload) as ev")
          ev3 = 0
          task_ev3.map do |t|
            ev3 = t.ev.to_f
          end
                
          #** AC取得 **
          # 該当週に着手のみの外注PV
          task_pv_out1 = Taskcopy
                .where(progressreport_id: prog.id)
                .where("planned_periodfr >= ? and planned_periodfr <= ?", period_fr, period_to)
                .where("planned_periodto > ?", period_to)
                .where(outsourcing: true)
                .select("sum(planned_workload) as pv")
          pv_out1 = 0
          task_pv_out1.map do |t|
            pv_out1 = t.pv.to_f
          end

          # 該当週に着手／完了の外注PV
          task_pv_out2 = Taskcopy
                .where(progressreport_id: prog.id)
                .where("planned_periodfr >= ? and planned_periodto <= ?", period_fr, period_to)
                .where(outsourcing: true)
                .select("sum(planned_workload) as pv")
          pv_out2 = 0
          task_pv_out2.map do |t|
            pv_out2 = t.pv.to_f
          end
        
          # 該当週に完了のみの外注PV
          task_pv_out3 = Taskcopy
                .where(progressreport_id: prog.id)
                .where("planned_periodfr < ?", period_fr)
                .where("planned_periodto >= ? and planned_periodto <= ?", period_fr, period_to)
                .where(outsourcing: true)
                .select("sum(planned_workload) as pv")
          pv_out3 = 0
          task_pv_out3.map do |t|
            pv_out3 = t.pv.to_f
          end
          
          # 該当週の日報から集計
          ac_rep = Workreport
                .joins(:dailyreport)
                .where(project_id: params[:id])
                .where("dailyreports.date >= ? and dailyreports.date <= ?", period_fr, period_to)
                .select("sum(workreports.hour) as sum_h,sum(workreports.minute) as sum_m,sum(workreports.over_h) as sum_oh, sum(workreports.over_m) as sum_om")
          pure_ac = 0
          ac_rep.map do |a|
            hours = a.sum_h.to_i + a.sum_oh.to_i
            minutes = a.sum_m.to_i + a.sum_om.to_i
            pure_ac = getWorkload(hours,minutes)
          end

          # ACに外注PVを加算
          ac = pure_ac + (pv_out1 * 0.5).round(2) + pv_out2 + (pv_out3 * 0.5).round(2)
      
        elsif prog_params[:outsouecing] == "3" then
          # 外注タスクはEVで見做し集計

          #** PV取得 **
          # 該当週に着手のみ
          task_pv1 = Taskcopy
                .where(progressreport_id: prog.id)
                .where("planned_periodfr >= ? and planned_periodfr <= ?", period_fr, period_to)
                .where("planned_periodto > ?", period_to)
                .select("sum(planned_workload) as pv")
          pv1 = 0
          task_pv1.map do |t|
            pv1 = t.pv.to_f
          end

          # 該当週に着手／完了
          task_pv2 = Taskcopy
                .where(progressreport_id: prog.id)
                .where("planned_periodfr >= ? and planned_periodto <= ?", period_fr, period_to)
                .select("sum(planned_workload) as pv")
          pv2 = 0
          task_pv2.map do |t|
            pv2 = t.pv.to_f
          end
        
          # 該当週に完了のみ
          task_pv3 = Taskcopy
                .where(progressreport_id: prog.id)
                .where("planned_periodfr < ?", period_fr)
                .where("planned_periodto >= ? and planned_periodto <= ?", period_fr, period_to)
                .select("sum(planned_workload) as pv")
          pv3 = 0
          task_pv3.map do |t|
            pv3 = t.pv.to_f
          end
        
          #** EV取得 **
          # 該当週に着手のみ
          task_ev1 = Taskcopy
                .where(progressreport_id: prog.id)
                .where("actual_periodfr >= ? and actual_periodfr <= ?", period_fr, period_to)
                .where("actual_periodto > ?", period_to)
                .select("sum(planned_workload) as ev")
          ev1 = 0
          task_ev1.map do |t|
            ev1 = t.ev.to_f
          end
        
          # 該当週に着手／完了
          task_ev2 = Taskcopy
                .where(progressreport_id: prog.id)
                .where("actual_periodfr >= ? and actual_periodto <= ?", period_fr, period_to)
                .select("sum(planned_workload) as ev")
          ev2 = 0
          task_ev2.map do |t|
            ev2 = t.ev.to_f
          end
        
          # 該当週に完了のみ
          task_ev3 = Taskcopy
                .where(progressreport_id: prog.id)
                .where("actual_periodfr < ?", period_fr)
                .where("actual_periodto >= ? and actual_periodto <= ?", period_fr, period_to)
                .select("sum(planned_workload) as ev")
          ev3 = 0
          task_ev3.map do |t|
            ev3 = t.ev.to_f
          end
                
          #** AC取得 **
          # 該当週に着手のみの外注EV
          task_ev_out1 = Taskcopy
                .where(progressreport_id: prog.id)
                .where("actual_periodfr >= ? and actual_periodfr <= ?", period_fr, period_to)
                .where("actual_periodto > ?", period_to)
                .where(outsourcing: true)
                .select("sum(planned_workload) as ev")
          ev_out1 = 0
          task_ev_out1.map do |t|
            ev_out1 = t.ev.to_f
          end
        
          # 該当週に着手／完了の外注EV
          task_ev_out2 = Taskcopy
                .where(progressreport_id: prog.id)
                .where("actual_periodfr >= ? and actual_periodto <= ?", period_fr, period_to)
                .where(outsourcing: true)
                .select("sum(planned_workload) as ev")
          ev_out2 = 0
          task_ev_out2.map do |t|
            ev_out2 = t.ev.to_f
          end
        
          # 該当週に完了のみの外注EV
          task_ev_out3 = Taskcopy
                .where(progressreport_id: prog.id)
                .where("actual_periodfr < ?", period_fr)
                .where("actual_periodto >= ? and actual_periodto <= ?", period_fr, period_to)
                .where(outsourcing: true)
                .select("sum(planned_workload) as ev")
          ev_out3 = 0
          task_ev_out3.map do |t|
            ev_out3 = t.ev.to_f
          end

          # 該当週の日報から集計
          ac_rep = Workreport
                .joins(:dailyreport)
                .where(project_id: params[:id])
                .where("dailyreports.date >= ? and dailyreports.date <= ?", period_fr, period_to)
                .select("sum(workreports.hour) as sum_h,sum(workreports.minute) as sum_m,sum(workreports.over_h) as sum_oh, sum(workreports.over_m) as sum_om")
          pure_ac = 0
          ac_rep.map do |a|
            hours = a.sum_h.to_i + a.sum_oh.to_i
            minutes = a.sum_m.to_i + a.sum_om.to_i
            pure_ac = getWorkload(hours,minutes)
          end

          # ACに外注EVを加算
          ac = pure_ac + (ev_out1 * 0.5).round(2) + ev_out2 + (ev_out3 * 0.5).round(2)

        else
          # 考慮せずそのまま集計

          #** PV取得 **
          # 該当週に着手のみ
          task_pv1 = Taskcopy
                .where(progressreport_id: prog.id)
                .where("planned_periodfr >= ? and planned_periodfr <= ?", period_fr, period_to)
                .where("planned_periodto > ?", period_to)
                .select("sum(planned_workload) as pv")
          pv1 = 0
          task_pv1.map do |t|
            pv1 = t.pv.to_f
          end

          # 該当週に着手／完了
          task_pv2 = Taskcopy
                .where(progressreport_id: prog.id)
                .where("planned_periodfr >= ? and planned_periodto <= ?", period_fr, period_to)
                .select("sum(planned_workload) as pv")
          pv2 = 0
          task_pv2.map do |t|
            pv2 = t.pv.to_f
          end
        
          # 該当週に完了のみ
          task_pv3 = Taskcopy
                .where(progressreport_id: prog.id)
                .where("planned_periodfr < ?", period_fr)
                .where("planned_periodto >= ? and planned_periodto <= ?", period_fr, period_to)
                .select("sum(planned_workload) as pv")
          pv3 = 0
          task_pv3.map do |t|
            pv3 = t.pv.to_f
          end
        
          #** EV取得 **
          # 該当週に着手のみ
          task_ev1 = Taskcopy
                .where(progressreport_id: prog.id)
                .where("actual_periodfr >= ? and actual_periodfr <= ?", period_fr, period_to)
                .where("actual_periodto > ?", period_to)
                .select("sum(planned_workload) as ev")
          ev1 = 0
          task_ev1.map do |t|
            ev1 = t.ev.to_f
          end
        
          # 該当週に着手／完了
          task_ev2 = Taskcopy
                .where(progressreport_id: prog.id)
                .where("actual_periodfr >= ? and actual_periodto <= ?", period_fr, period_to)
                .select("sum(planned_workload) as ev")
          ev2 = 0
          task_ev2.map do |t|
            ev2 = t.ev.to_f
          end
        
          # 該当週に完了のみ
          task_ev3 = Taskcopy
                .where(progressreport_id: prog.id)
                .where("actual_periodfr < ?", period_fr)
                .where("actual_periodto >= ? and actual_periodto <= ?", period_fr, period_to)
                .select("sum(planned_workload) as ev")
          ev3 = 0
          task_ev3.map do |t|
            ev3 = t.ev.to_f
          end
                
          #** AC取得 **
          # 該当週の日報から集計
          ac_rep = Workreport
                .joins(:dailyreport)
                .where(project_id: params[:id])
                .where("dailyreports.date >= ? and dailyreports.date <= ?", period_fr, period_to)
                .select("sum(workreports.hour) as sum_h,sum(workreports.minute) as sum_m,sum(workreports.over_h) as sum_oh, sum(workreports.over_m) as sum_om")
          ac = 0
          ac_rep.map do |a|
            hours = a.sum_h.to_i + a.sum_oh.to_i
            minutes = a.sum_m.to_i + a.sum_om.to_i
            ac = getWorkload(hours,minutes)
          end

        end

        #** EVM登録 **
        evm = Evm.new(progressreport_id: prog.id, level: "project", date_fr: period_fr, date_to: period_to)
        
        # BAC
        evm.bac = bac
        #** 週単位 **
        # PV
        evm.pv = (pv1 * 0.5).round(2) + pv2 + (pv3 * 0.5).round(2)
        # EV
        evm.ev = (ev1 * 0.5).round(2) + ev2 + (ev3 * 0.5).round(2)
        # AC
        evm.ac = ac
        # SV
        evm.sv = evm.ev - evm.pv
        # CV
        evm.cv = evm.ev - evm.ac
        # SPI
        if evm.pv == 0 then
          evm.spi = 0
        else
          evm.spi = (evm.ev / evm.pv.to_f).round(2)
        end
        # CPI
        if evm.ac == 0 then
          evm.cpi = 0
        else
          evm.cpi = (evm.ev / evm.ac.to_f).round(2)
        end
        #** 累積 **
        # PV
        pv_sum += evm.pv
        evm.pv_sum = pv_sum
        # EV
        ev_sum += evm.ev
        evm.ev_sum = ev_sum
        # AC
        ac_sum += evm.ac
        evm.ac_sum = ac_sum
        # SV
        evm.sv_sum = ev_sum - pv_sum
        # CV
        evm.cv_sum = ev_sum - ac_sum
        # SPI
        if pv_sum == 0 then
          evm.spi_sum = 0
        else
          evm.spi_sum = (ev_sum / pv_sum.to_f).round(2)
        end
        # CPI
        if ac_sum == 0 then
          evm.cpi_sum = 0
        else
          evm.cpi_sum = (ev_sum / ac_sum.to_f).round(2)
        end
        # ETC
        if evm.cpi_sum == 0 then
          evm.etc = 0
        else
          evm.etc = (bac - ev_sum) / evm.cpi_sum
        end
        # EAC
        evm.eac = ac_sum + evm.etc
        # VAC
        evm.vac = bac - evm.eac
        # 保存
        evm.save!

        # +7日
        period_fr = period_to.tomorrow
        period_to = period_to.days_since(7)

      end   # roop-end

      # 最終週を計測
      if prog_params[:outsourcing] == "1" then
        # 外注タスクは除外して集計

        #** PV取得 **
        # 該当週に着手のみ
        task_pv1 = Taskcopy
              .where(progressreport_id: prog.id)
              .where("planned_periodfr >= ? and planned_periodfr <= ?", period_fr, period_to)
              .where("planned_periodto > ?", period_to)
              .where(outsourcing: false)
              .select("sum(planned_workload) as pv")
        pv1 = 0
        task_pv1.map do |t|
          pv1 = t.pv.to_f
        end

        # 該当週に着手／完了
        task_pv2 = Taskcopy
              .where(progressreport_id: prog.id)
              .where("planned_periodfr >= ? and planned_periodto <= ?", period_fr, period_to)
              .where(outsourcing: false)
              .select("sum(planned_workload) as pv")
        pv2 = 0
        task_pv2.map do |t|
          pv2 = t.pv.to_f
        end
      
        # 該当週に完了のみ
        task_pv3 = Taskcopy
              .where(progressreport_id: prog.id)
              .where("planned_periodfr < ?", period_fr)
              .where("planned_periodto >= ? and planned_periodto <= ?", period_fr, period_to)
              .where(outsourcing: false)
              .select("sum(planned_workload) as pv")
        pv3 = 0
        task_pv3.map do |t|
          pv3 = t.pv.to_f
        end
      
        #** EV取得 **
        # 該当週に着手のみ
        task_ev1 = Taskcopy
              .where(progressreport_id: prog.id)
              .where("actual_periodfr >= ? and actual_periodfr <= ?", period_fr, period_to)
              .where("actual_periodto > ?", period_to)
              .where(outsourcing: false)
              .select("sum(planned_workload) as ev")
        ev1 = 0
        task_ev1.map do |t|
          ev1 = t.ev.to_f
        end
      
        # 該当週に着手／完了
        task_ev2 = Taskcopy
              .where(progressreport_id: prog.id)
              .where("actual_periodfr >= ? and actual_periodto <= ?", period_fr, period_to)
              .where(outsourcing: false)
              .select("sum(planned_workload) as ev")
        ev2 = 0
        task_ev2.map do |t|
          ev2 = t.ev.to_f
        end
      
        # 該当週に完了のみ
        task_ev3 = Taskcopy
              .where(progressreport_id: prog.id)
              .where("actual_periodfr < ?", period_fr)
              .where("actual_periodto >= ? and actual_periodto <= ?", period_fr, period_to)
              .where(outsourcing: false)
              .select("sum(planned_workload) as ev")
        ev3 = 0
        task_ev3.map do |t|
          ev3 = t.ev.to_f
        end
              
        #** AC取得 **
        # 該当週の日報から集計
        ac_rep = Workreport
              .joins(:dailyreport)
              .where(project_id: params[:id])
              .where("dailyreports.date >= ? and dailyreports.date <= ?", period_fr, period_to)
              .select("sum(workreports.hour) as sum_h,sum(workreports.minute) as sum_m,sum(workreports.over_h) as sum_oh, sum(workreports.over_m) as sum_om")
        ac = 0
        ac_rep.map do |a|
          hours = a.sum_h.to_i + a.sum_oh.to_i
          minutes = a.sum_m.to_i + a.sum_om.to_i
          ac = getWorkload(hours,minutes)
        end
        
      elsif prog_params[:outsourcing] == "2" then
        # 外注タスクはPVで見做し集計

        #** PV取得 **
        # 該当週に着手のみ
        task_pv1 = Taskcopy
              .where(progressreport_id: prog.id)
              .where("planned_periodfr >= ? and planned_periodfr <= ?", period_fr, period_to)
              .where("planned_periodto > ?", period_to)
              .select("sum(planned_workload) as pv")
        pv1 = 0
        task_pv1.map do |t|
          pv1 = t.pv.to_f
        end

        # 該当週に着手／完了
        task_pv2 = Taskcopy
              .where(progressreport_id: prog.id)
              .where("planned_periodfr >= ? and planned_periodto <= ?", period_fr, period_to)
              .select("sum(planned_workload) as pv")
        pv2 = 0
        task_pv2.map do |t|
          pv2 = t.pv.to_f
        end
      
        # 該当週に完了のみ
        task_pv3 = Taskcopy
              .where(progressreport_id: prog.id)
              .where("planned_periodfr < ?", period_fr)
              .where("planned_periodto >= ? and planned_periodto <= ?", period_fr, period_to)
              .select("sum(planned_workload) as pv")
        pv3 = 0
        task_pv3.map do |t|
          pv3 = t.pv.to_f
        end
      
        #** EV取得 **
        # 該当週に着手のみ
        task_ev1 = Taskcopy
              .where(progressreport_id: prog.id)
              .where("actual_periodfr >= ? and actual_periodfr <= ?", period_fr, period_to)
              .where("actual_periodto > ?", period_to)
              .select("sum(planned_workload) as ev")
        ev1 = 0
        task_ev1.map do |t|
          ev1 = t.ev.to_f
        end
      
        # 該当週に着手／完了
        task_ev2 = Taskcopy
              .where(progressreport_id: prog.id)
              .where("actual_periodfr >= ? and actual_periodto <= ?", period_fr, period_to)
              .select("sum(planned_workload) as ev")
        ev2 = 0
        task_ev2.map do |t|
          ev2 = t.ev.to_f
        end
      
        # 該当週に完了のみ
        task_ev3 = Taskcopy
              .where(progressreport_id: prog.id)
              .where("actual_periodfr < ?", period_fr)
              .where("actual_periodto >= ? and actual_periodto <= ?", period_fr, period_to)
              .select("sum(planned_workload) as ev")
        ev3 = 0
        task_ev3.map do |t|
          ev3 = t.ev.to_f
        end
              
        #** AC取得 **
        # 該当週に着手のみの外注PV
        task_pv_out1 = Taskcopy
              .where(progressreport_id: prog.id)
              .where("planned_periodfr >= ? and planned_periodfr <= ?", period_fr, period_to)
              .where("planned_periodto > ?", period_to)
              .where(outsourcing: true)
              .select("sum(planned_workload) as pv")
        pv_out1 = 0
        task_pv_out1.map do |t|
          pv_out1 = t.pv.to_f
        end

        # 該当週に着手／完了の外注PV
        task_pv_out2 = Taskcopy
              .where(progressreport_id: prog.id)
              .where("planned_periodfr >= ? and planned_periodto <= ?", period_fr, period_to)
              .where(outsourcing: true)
              .select("sum(planned_workload) as pv")
        pv_out2 = 0
        task_pv_out2.map do |t|
          pv_out2 = t.pv.to_f
        end
      
        # 該当週に完了のみの外注PV
        task_pv_out3 = Taskcopy
              .where(progressreport_id: prog.id)
              .where("planned_periodfr < ?", period_fr)
              .where("planned_periodto >= ? and planned_periodto <= ?", period_fr, period_to)
              .where(outsourcing: true)
              .select("sum(planned_workload) as pv")
        pv_out3 = 0
        task_pv_out3.map do |t|
          pv_out3 = t.pv.to_f
        end
        
        # 該当週の日報から集計
        ac_rep = Workreport
              .joins(:dailyreport)
              .where(project_id: params[:id])
              .where("dailyreports.date >= ? and dailyreports.date <= ?", period_fr, period_to)
              .select("sum(workreports.hour) as sum_h,sum(workreports.minute) as sum_m,sum(workreports.over_h) as sum_oh, sum(workreports.over_m) as sum_om")
        pure_ac = 0
        ac_rep.map do |a|
          hours = a.sum_h.to_i + a.sum_oh.to_i
          minutes = a.sum_m.to_i + a.sum_om.to_i
          pure_ac = getWorkload(hours,minutes)
        end

        # ACに外注PVを加算
        ac = pure_ac + (pv_out1 * 0.5).round(2) + pv_out2 + (pv_out3 * 0.5).round(2)
    
      elsif prog_params[:outsouecing] == "3" then
        # 外注タスクはEVで見做し集計

        #** PV取得 **
        # 該当週に着手のみ
        task_pv1 = Taskcopy
              .where(progressreport_id: prog.id)
              .where("planned_periodfr >= ? and planned_periodfr <= ?", period_fr, period_to)
              .where("planned_periodto > ?", period_to)
              .select("sum(planned_workload) as pv")
        pv1 = 0
        task_pv1.map do |t|
          pv1 = t.pv.to_f
        end

        # 該当週に着手／完了
        task_pv2 = Taskcopy
              .where(progressreport_id: prog.id)
              .where("planned_periodfr >= ? and planned_periodto <= ?", period_fr, period_to)
              .select("sum(planned_workload) as pv")
        pv2 = 0
        task_pv2.map do |t|
          pv2 = t.pv.to_f
        end
      
        # 該当週に完了のみ
        task_pv3 = Taskcopy
              .where(progressreport_id: prog.id)
              .where("planned_periodfr < ?", period_fr)
              .where("planned_periodto >= ? and planned_periodto <= ?", period_fr, period_to)
              .select("sum(planned_workload) as pv")
        pv3 = 0
        task_pv3.map do |t|
          pv3 = t.pv.to_f
        end
      
        #** EV取得 **
        # 該当週に着手のみ
        task_ev1 = Taskcopy
              .where(progressreport_id: prog.id)
              .where("actual_periodfr >= ? and actual_periodfr <= ?", period_fr, period_to)
              .where("actual_periodto > ?", period_to)
              .select("sum(planned_workload) as ev")
        ev1 = 0
        task_ev1.map do |t|
          ev1 = t.ev.to_f
        end
      
        # 該当週に着手／完了
        task_ev2 = Taskcopy
              .where(progressreport_id: prog.id)
              .where("actual_periodfr >= ? and actual_periodto <= ?", period_fr, period_to)
              .select("sum(planned_workload) as ev")
        ev2 = 0
        task_ev2.map do |t|
          ev2 = t.ev.to_f
        end
      
        # 該当週に完了のみ
        task_ev3 = Taskcopy
              .where(progressreport_id: prog.id)
              .where("actual_periodfr < ?", period_fr)
              .where("actual_periodto >= ? and actual_periodto <= ?", period_fr, period_to)
              .select("sum(planned_workload) as ev")
        ev3 = 0
        task_ev3.map do |t|
          ev3 = t.ev.to_f
        end
              
        #** AC取得 **
        # 該当週に着手のみの外注EV
        task_ev_out1 = Taskcopy
              .where(progressreport_id: prog.id)
              .where("actual_periodfr >= ? and actual_periodfr <= ?", period_fr, period_to)
              .where("actual_periodto > ?", period_to)
              .where(outsourcing: true)
              .select("sum(planned_workload) as ev")
        ev_out1 = 0
        task_ev_out1.map do |t|
          ev_out1 = t.ev.to_f
        end
      
        # 該当週に着手／完了の外注EV
        task_ev_out2 = Taskcopy
              .where(progressreport_id: prog.id)
              .where("actual_periodfr >= ? and actual_periodto <= ?", period_fr, period_to)
              .where(outsourcing: true)
              .select("sum(planned_workload) as ev")
        ev_out2 = 0
        task_ev_out2.map do |t|
          ev_out2 = t.ev.to_f
        end
      
        # 該当週に完了のみの外注EV
        task_ev_out3 = Taskcopy
              .where(progressreport_id: prog.id)
              .where("actual_periodfr < ?", period_fr)
              .where("actual_periodto >= ? and actual_periodto <= ?", period_fr, period_to)
              .where(outsourcing: true)
              .select("sum(planned_workload) as ev")
        ev_out3 = 0
        task_ev_out3.map do |t|
          ev_out3 = t.ev.to_f
        end

        # 該当週の日報から集計
        ac_rep = Workreport
              .joins(:dailyreport)
              .where(project_id: params[:id])
              .where("dailyreports.date >= ? and dailyreports.date <= ?", period_fr, period_to)
              .select("sum(workreports.hour) as sum_h,sum(workreports.minute) as sum_m,sum(workreports.over_h) as sum_oh, sum(workreports.over_m) as sum_om")
        pure_ac = 0
        ac_rep.map do |a|
          hours = a.sum_h.to_i + a.sum_oh.to_i
          minutes = a.sum_m.to_i + a.sum_om.to_i
          pure_ac = getWorkload(hours,minutes)
        end

        # ACに外注EVを加算
        ac = pure_ac + (ev_out1 * 0.5).round(2) + ev_out2 + (ev_out3 * 0.5).round(2)

      else
        # 考慮せずそのまま集計

        #** PV取得 **
        # 該当週に着手のみ
        task_pv1 = Taskcopy
              .where(progressreport_id: prog.id)
              .where("planned_periodfr >= ? and planned_periodfr <= ?", period_fr, period_to)
              .where("planned_periodto > ?", period_to)
              .select("sum(planned_workload) as pv")
        pv1 = 0
        task_pv1.map do |t|
          pv1 = t.pv.to_f
        end

        # 該当週に着手／完了
        task_pv2 = Taskcopy
              .where(progressreport_id: prog.id)
              .where("planned_periodfr >= ? and planned_periodto <= ?", period_fr, period_to)
              .select("sum(planned_workload) as pv")
        pv2 = 0
        task_pv2.map do |t|
          pv2 = t.pv.to_f
        end
      
        # 該当週に完了のみ
        task_pv3 = Taskcopy
              .where(progressreport_id: prog.id)
              .where("planned_periodfr < ?", period_fr)
              .where("planned_periodto >= ? and planned_periodto <= ?", period_fr, period_to)
              .select("sum(planned_workload) as pv")
        pv3 = 0
        task_pv3.map do |t|
          pv3 = t.pv.to_f
        end
      
        #** EV取得 **
        # 該当週に着手のみ
        task_ev1 = Taskcopy
              .where(progressreport_id: prog.id)
              .where("actual_periodfr >= ? and actual_periodfr <= ?", period_fr, period_to)
              .where("actual_periodto > ?", period_to)
              .select("sum(planned_workload) as ev")
        ev1 = 0
        task_ev1.map do |t|
          ev1 = t.ev.to_f
        end
      
        # 該当週に着手／完了
        task_ev2 = Taskcopy
              .where(progressreport_id: prog.id)
              .where("actual_periodfr >= ? and actual_periodto <= ?", period_fr, period_to)
              .select("sum(planned_workload) as ev")
        ev2 = 0
        task_ev2.map do |t|
          ev2 = t.ev.to_f
        end
      
        # 該当週に完了のみ
        task_ev3 = Taskcopy
              .where(progressreport_id: prog.id)
              .where("actual_periodfr < ?", period_fr)
              .where("actual_periodto >= ? and actual_periodto <= ?", period_fr, period_to)
              .select("sum(planned_workload) as ev")
        ev3 = 0
        task_ev3.map do |t|
          ev3 = t.ev.to_f
        end
              
        #** AC取得 **
        # 該当週の日報から集計
        ac_rep = Workreport
              .joins(:dailyreport)
              .where(project_id: params[:id])
              .where("dailyreports.date >= ? and dailyreports.date <= ?", period_fr, period_to)
              .select("sum(workreports.hour) as sum_h,sum(workreports.minute) as sum_m,sum(workreports.over_h) as sum_oh, sum(workreports.over_m) as sum_om")
        ac = 0
        ac_rep.map do |a|
          hours = a.sum_h.to_i + a.sum_oh.to_i
          minutes = a.sum_m.to_i + a.sum_om.to_i
          ac = getWorkload(hours,minutes)
        end

      end

      #** EVM登録 **
      evm = Evm.new(progressreport_id: prog.id, level: "project", date_fr: period_fr, date_to: period_to)
      
      # BAC
      evm.bac = bac
      #** 週単位 **
      # PV
      evm.pv = (pv1 * 0.5).round(2) + pv2 + (pv3 * 0.5).round(2)
      # EV
      evm.ev = (ev1 * 0.5).round(2) + ev2 + (ev3 * 0.5).round(2)
      # AC
      evm.ac = ac
      # SV
      evm.sv = evm.ev - evm.pv
      # CV
      evm.cv = evm.ev - evm.ac
      # SPI
      if evm.pv == 0 then
        evm.spi = 0
      else
        evm.spi = (evm.ev / evm.pv.to_f).round(2)
      end
      # CPI
      if evm.ac == 0 then
        evm.cpi = 0
      else
        evm.cpi = (evm.ev / evm.ac.to_f).round(2)
      end
      #** 累積 **
      # PV
      pv_sum += evm.pv
      evm.pv_sum = pv_sum
      # EV
      ev_sum += evm.ev
      evm.ev_sum = ev_sum
      # AC
      ac_sum += evm.ac
      evm.ac_sum = ac_sum
      # SV
      evm.sv_sum = ev_sum - pv_sum
      # CV
      evm.cv_sum = ev_sum - ac_sum
      # SPI
      if pv_sum == 0 then
        evm.spi_sum = 0
      else
        evm.spi_sum = (ev_sum / pv_sum.to_f).round(2)
      end
      # CPI
      if ac_sum == 0 then
        evm.cpi_sum = 0
      else
        evm.cpi_sum = (ev_sum / ac_sum.to_f).round(2)
      end
      # ETC
      if evm.cpi_sum == 0 then
        evm.etc = 0
      else
        evm.etc = (bac - ev_sum) / evm.cpi_sum
      end
      # EAC
      evm.eac = ac_sum + evm.etc
      # VAC
      evm.vac = bac - evm.eac
      # 保存
      evm.save!

      # *** Task Actual ***
      # 集計は外注タスク以外が対象
      tasks = Taskcopy
                .where(progressreport_id: prog.id)
                .where(outsourcing: false)
                .order(:number)
      tasks.map do |t|

        # 所定時間、時間外時間
        act1 = Workreport
                .where(task_id: t.task_id)
                .select("sum(hour) as hour, sum(minute) as minute, sum(over_h) as over_h, sum(over_m) as over_m")
        total_hour = 0
        total_minute = 0
        over_h = 0
        over_m = 0
        act1.map do |a1|
          over_h = a1.over_h.to_f
          over_m = a1.over_m.to_f
          total_hour = a1.hour.to_f + over_h
          total_minute = a1.minute.to_f + over_m
        end
  
        # 完了後の所定時間、時間外時間
        act2 = Workreport
                .joins(:dailyreport)
                .where(task_id: t.task_id)
                .where("dailyreports.date > ?", t.actual_periodto)
                .select("sum(hour) as hour, sum(minute) as minute, sum(workreports.over_h) as over_h, sum(workreports.over_m) as over_m")
        after_total_hour = 0
        after_total_minute = 0
        after_over_h = 0
        after_over_m = 0
        act2.map do |a2|
          after_over_h = a2.over_h.to_f
          after_over_m = a2.over_m.to_f
          after_total_hour = a2.hour.to_f + after_over_h
          after_total_minute = a2.minute.to_f + after_over_m
        end

        # タスク実績登録
        taskact = Taskactual.new(progressreport_id: prog.id, taskcopy_id: t.id)
        taskact.total_workload = getWorkload(total_hour, total_minute)
        taskact.overtime_workload = getWorkload(over_h, over_m)
        taskact.after_total_workload = getWorkload(after_total_hour, after_total_minute)
        taskact.after_overtime_workload = getWorkload(after_over_h, after_over_m)
        taskact.save!
      end

      # *** Phase Actual ***
      # 集計は外注タスク以外が対象
      phases = Phasecopy
                .where(progressreport_id: prog.id)
                .order(:number)
      phases.map do |ph|

        taskact = Taskactual
                    .joins(:taskcopy)
                    .where("taskcopies.phase_id = ?", ph.phase_id)
                    .select("sum(total_workload) as total_workload, sum(overtime_workload) as overtime_workload, sum(after_total_workload) as after_total_workload, sum(after_overtime_workload) as after_overtime_workload")
        total_workload = 0
        overtime_workload = 0
        after_total_workload = 0
        after_overtime_workload = 0
        total_cost = 0
        taskact.map do |ta|
          total_workload = (ta.total_workload.to_f / 20).round(2)
          overtime_workload = (ta.overtime_workload.to_f / 20).round(2)
          after_total_workload = (ta.after_total_workload.to_f / 20).round(2)
          after_overtime_workload = (ta.after_overtime_workload.to_f / 20).round(2)
          total_cost = total_workload * (ph.planned_cost.to_f / ph.planned_workload.to_f).round
        end

        # 開始日
        taskfr = Taskcopy
                    .where(progressreport_id: prog.id)
                    .where(phase_id: ph.phase_id)
                    .where.not(actual_periodfr: nil)
                    .select(:actual_periodfr)
                    .order(:actual_periodfr)
                    .limit(1)
        periodfr = ""
        taskfr.map do |fr|
          if periodfr.blank? then
            periodfr = fr.actual_periodfr
          end
        end

        periodto = ""
        if periodfr.present? then
          # 終了日
          if Taskcopy.exists?(progressreport_id: prog.id, phase_id: ph.phase_id, actual_periodto: nil) then
            # 終了日未入力が１件でもある場合
          else
            # 終了日が全て入力されている場合
            taskto = Taskcopy
                      .where(progressreport_id: prog.id)
                      .where(phase_id: ph.phase_id)
                      .select(:actual_periodto)
                      .order(actual_periodto: :desc)
                      .limit(1)
            taskto.map do |to|
              periodto = to.actual_periodto
            end
          end
        end

        # 工程実績登録
        phaseact = Phaseactual.new(progressreport_id: prog.id, phasecopy_id: ph.id)
        phaseact.periodfr = periodfr
        phaseact.periodto = periodto
        phaseact.total_cost = total_cost
        phaseact.total_workload = total_workload
        phaseact.overtime_workload = overtime_workload
        phaseact.after_total_workload = after_total_workload
        phaseact.after_overtime_workload = after_overtime_workload
        phaseact.save!
        
      end

    end # ActiveRecord

    render json: { status: 200, message: "Create Success!" }

  rescue => e
  
    render json: { status: 500, message: "Create Error"}

  end

  private
  # ストロングパラメータ
  def prog_params
    params.permit(:make_id, :totaling_day, :outsourcing)
  end

  # 時分から工数（人日）換算
  def getWorkload(h,m)
    hours = h + m.div(60)
    minutes = m.modulo(60)

    if minutes <= 15 then
      # 15分以下は0h
    elsif minutes <= 45 then
      # 16~45分以下は0.5h
      hours += 0.5
    else
      #46分以上は1h
      hours += 1
    end

    # 1人日＝8時間で換算(四捨五入)
    return (hours.to_f / 8).round(2)
  end

end
