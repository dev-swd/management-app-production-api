class Api::V1::DailyreportsController < ApplicationController

  # 社員番号、年月を指定して、対象月分の日報明細を取得
  # 該当レポートがなければ、当該月分の日報明細を新規作成
  # （一覧画面用）
  def index_by_emp
    if Dailyreport.where(employee_id: params[:emp_id], ym: params[:y] + params[:m]).empty? then
      dt = Date.new(params[:y].to_i, params[:m].to_i, 1);
      dt_end = dt.next_month
      cnt = 1;
      ActiveRecord::Base.transaction do
        while dt < dt_end do
          break if cnt ==32
          daily = Dailyreport.new()
          daily.employee_id = params[:emp_id]
          daily.ym = params[:y] + params[:m]
          daily.date = dt
          daily.work_prescribed_h = 0
          daily.work_prescribed_m = 0
          daily.work_over_h = 0
          daily.work_over_m = 0
          daily.status = "未入力"
          daily.save!
          dt = dt.tomorrow
          cnt += 1
        end
      end
    end

    emp = Employee.select(:name).find(params[:emp_id])
    dailys = Dailyreport.where(employee_id: params[:emp_id], ym: params[:y] + params[:m]).order(:date)
    render json: { status: 200, emp: emp, dailys: dailys }

  rescue => e

    render json: { status: 500, message: "Update Error"}

  end

  # ID指定で日報を１件取得（詳細、編集画面用）
  def show
    daily = Dailyreport.find(params[:id])
    render json: { status: 200, daily: daily }
  end

  # 日報１件更新
  # 入力された各諸元から、所定時間、時間外時間、深夜時間も算定して更新
  # ※各入力諸元の入力チェックは対応していない
  def update
    ActiveRecord::Base.transaction do
      daily = Dailyreport.find_or_initialize_by(id: params[:id])
      daily.kbn = daily_params[:kbn]
      daily.kbn_reason = daily_params[:kbn_reason]
      daily.prescribed_frh = daily_params[:prescribed_frh]
      daily.prescribed_frm = daily_params[:prescribed_frm]
      daily.prescribed_toh = daily_params[:prescribed_toh]
      daily.prescribed_tom = daily_params[:prescribed_tom]
      daily.lunch_frh = daily_params[:lunch_frh]
      daily.lunch_frm = daily_params[:lunch_frm]
      daily.lunch_toh = daily_params[:lunch_toh]
      daily.lunch_tom = daily_params[:lunch_tom]
      daily.over_reason = daily_params[:over_reason]
      daily.over_frh = daily_params[:over_frh]
      daily.over_frm = daily_params[:over_frm]
      daily.over_toh = daily_params[:over_toh]
      daily.over_tom = daily_params[:over_tom]
      daily.rest_frh = daily_params[:rest_frh]
      daily.rest_frm = daily_params[:rest_frm]
      daily.rest_toh = daily_params[:rest_toh]
      daily.rest_tom = daily_params[:rest_tom]
      daily.late_reason = daily_params[:late_reason]
      daily.late_h = daily_params[:late_h]
      daily.late_m = daily_params[:late_m]
      daily.goout_reason = daily_params[:goout_reason]
      daily.goout_frh = daily_params[:goout_frh]
      daily.goout_frm = daily_params[:goout_frm]
      daily.goout_toh = daily_params[:goout_toh]
      daily.goout_tom = daily_params[:goout_tom]
      daily.early_reason = daily_params[:early_reason]
      daily.early_h = daily_params[:early_h]
      daily.early_m = daily_params[:early_m]
      daily.status = daily_params[:status]
      daily.prescribed_h = nil
      daily.prescribed_m = nil
      daily.over_h = nil
      daily.over_m = nil
      daily.midnight_h = nil
      daily.midnight_m = nil

      if daily_params[:kbn] != "休暇" then
        prescribed_fr= getTime(daily_params[:prescribed_frh], daily_params[:prescribed_frm])
        prescribed_to= getTime(daily_params[:prescribed_toh], daily_params[:prescribed_tom])
        lunch_fr = getTime(daily_params[:lunch_frh], daily_params[:lunch_frm])
        lunch_to = getTime(daily_params[:lunch_toh], daily_params[:lunch_tom])

        # 遅刻時間の算定
        if daily_params[:late_h].present? then
          late = getTime(daily_params[:late_h], daily_params[:late_m])
          if late < lunch_fr then
            # 遅刻時間が休憩前の場合
            late_value = late - prescribed_fr
          elsif lunch_fr <= late && late <= lunch_to then
            # 遅刻時間が休憩時間内の場合
            late_value = lunch_fr - prescribed_fr
          else
            # 遅刻時間が休憩後の場合
            late_value = (lunch_fr - prescribed_fr) + (late - lunch_to) 
          end
        else
          late_value = 0
        end

        # 外出時間の算定
        if daily_params[:goout_frh].present? then
          goout_fr = getTime(daily_params[:goout_frh], daily_params[:goout_frm])
          goout_to = getTime(daily_params[:goout_toh], daily_params[:goout_tom])
          if goout_to <= lunch_fr then
            goout_value = goout_to - goout_fr
          elsif goout_fr <= lunch_fr then
            if goout_to <= lunch_to then
              goout_value = lunch_fr - goout_fr
            else
              goout_value = (goout_to - lunch_to) + (lunch_fr - goout_fr)
            end
          elsif goout_fr <= lunch_to then
            if goout_to <= lunch_to then
              goout_value = 0
            else
              goout_value = goout_to - lunch_to
            end
          else
            goout_value = goout_to - goout_fr
          end
        else
          goout_value = 0
        end

        # 早退時間の算定
        if daily_params[:early_h].present? then
          early = getTime(daily_params[:early_h], daily_params[:early_m])
          if early < lunch_fr then
            # 早退時間が休憩前の場合
            early_value = (lunch_fr - early) + (prescribed_to - lunch_to)
          elsif lunch_fr <= early && early <= lunch_to then
            # 早退時間が休憩時間内の場合
            early_value = prescribed_to - lunch_to
          else
            # 早退時間が休憩後の場合
            early_value = prescribed_to - early
          end
        else
          early_value = 0
        end

        # 所定時間の算定
        prescribed = (lunch_fr - prescribed_fr) + (prescribed_to - lunch_to) - late_value - goout_value - early_value
        p_sec = prescribed % 60
        p_min = ((prescribed - p_sec) / 60) % 60
        p_hr = (prescribed - p_sec - p_min * 60) / (60 ** 2)
        daily.prescribed_h = p_hr.to_i
        daily.prescribed_m = p_min.to_i
      
        # 時間外の算定
        if daily_params[:over_frh].present? then
          over_fr = getTime(daily_params[:over_frh], daily_params[:over_frm])
          over_to = getTime(daily_params[:over_toh], daily_params[:over_tom])
          if daily_params[:rest_frh].present? then
            rest_fr = getTime(daily_params[:rest_frh], daily_params[:rest_frm])
            rest_to = getTime(daily_params[:rest_toh], daily_params[:rest_tom])
            over = (rest_fr - over_fr) + (over_to - rest_to)
          else
            over = (over_to - over_fr)
          end
          o_sec = over % 60
          o_min = ((over - o_sec) / 60) % 60
          o_hr = (over - o_sec - o_min * 60) / (60 ** 2)
          daily.over_h = o_hr.to_i
          daily.over_m = o_min.to_i
        else
          daily.over_h = 0
          daily.over_m = 0
        end

        # 深夜時間の算定
        mid_fr = Time.local(2022,1,1,22,0,0)
        mid_to = Time.local(2022,1,2,5,0,0)

        # 所定時間における深夜時間を算定
        if daily_params[:kbn] === "通常" then
          # 通常の場合、所定時間が深夜になることはない
          mid_value1 = 0
        else
          # 時差、休出の場合、所定時間の内、深夜時間を算出

          # 除外時間（休憩、外出）の算定
          if daily_params[:goout_frh].blank? then
            # 外出がなければ休憩時間のみで除外算定

            if lunch_to <= mid_fr then
              exclution_value1 = 0
            elsif lunch_fr <= mid_fr then
              if lunch_to <= mid_to then
                exclution_value1 = lunch_to - mid_fr
              else
                exclution_value1 = 7 * 60 * 60
              end
            elsif lunch_fr <= mid_to then
              if lunch_to <= mid_to then
                exclution_value1 = lunch_to - lunch_fr
              else
                exclution_value1 = mid_to - lunch_fr
              end
            else
              exclution_value1 = 0
            end
            exclution_value2 = 0

          else
            # 外出があれば休憩時間と外出時間で除外算定

            if lunch_to <= goout_fr then
              # 休憩と外出は重複していない => lunchとgooutそれぞれで除外判断

              # 休憩時間
              if lunch_to <= mid_fr then
                exclution_value1 = 0
              elsif lunch_fr <= mid_fr then
                if lunch_to <= mid_to then
                  exclution_value1 = lunch_to - mid_fr
                else
                  exclution_value1 = 7 * 60 * 60
                end
              elsif lunch_fr <= mid_to then
                if lunch_to <= mid_to then
                  exclution_value1 = lunch_to - lunch_fr
                else
                  exclution_value1 = mid_to - lunch_fr
                end
              else
                exclution_value1 = 0
              end
              
              # 外出時間
              if goout_to <= mid_fr then
                exclution_value2 = 0
              elsif goout_fr <= mid_fr then
                if goout_to <= mid_to then
                  exclution_value2 = goout_to - mid_fr
                else
                  exclution_value2 = 7 * 60 * 60
                end
              elsif goout_fr <= mid_to then
                if goout_to <= mid_to then
                  exclution_value2 = goout_to - goout_fr
                else
                  exclution_value2 = mid_to - goout_fr
                end
              else
                exclution_value2 = 0
              end

            elsif lunch_fr <= goout_fr then
              if lunch_to <= goout_to then
                # 休憩開始〜休憩終了で除外判断
                exclution_fr = lunch_fr
                exclution_to = lunch_to
              else
                # 休憩開始〜外出終了で除外判断
                exclution_fr = lunch_fr
                exclution_to = goout_to
              end
              if exclution_to <= mid_fr then
                exclution_value1 = 0
              elsif exclution_fr <= mid_fr then
                if exclution_to <= mid_to then
                  exclution_value1 = exclution_to - mid_fr
                else
                  exclution_value1 = 7 * 60 * 60
                end
              elsif exclution_fr <= mid_to then
                if exclution_to <= mid_to then
                  exclution_value1 = exclution_to - exclution_fr
                else
                  exclution_value1 = mid_to - exclution_fr
                end
              else
                exclution_value1 = 0
              end
              exclution_value2 = 0

            elsif lunch_fr <= goout_to then
              if lunch_to <= goout_to then
                # 休憩時間が外出に包含されている => 外出時間で除外判断
                exclution_fr = goout_fr
                exclution_to = goout_to
              else
                # 外出開始〜休憩終了で除外判断
                exclution_fr = goout_fr
                exclution_to = lunch_to
              end
              if exclution_to <= mid_fr then
                exclution_value1 = 0
              elsif exclution_fr <= mid_fr then
                if exclution_to <= mid_to then
                  exclution_value1 = exclution_to - mid_fr
                else
                  exclution_value1 = 7 * 60 * 60
                end
              elsif exclution_fr <= mid_to then
                if exclution_to <= mid_to then
                  exclution_value1 = exclution_to - exclution_fr
                else
                  exclution_value1 = mid_to - exclution_fr
                end
              else
                exclution_value1 = 0
              end
              exclution_value2 = 0

            else
              # 休憩と外出は重複していない => lunchとgooutそれぞれで除外判断

              # 休憩時間
              if lunch_to <= mid_fr then
                exclution_value1 = 0
              elsif lunch_fr <= mid_fr then
                if lunch_to <= mid_to then
                  exclution_value1 = lunch_to - mid_fr
                else
                  exclution_value1 = 7 * 60 * 60
                end
              elsif lunch_fr <= mid_to then
                if lunch_to <= mid_to then
                  exclution_value1 = lunch_to - lunch_fr
                else
                  exclution_value1 = mid_to - lunch_fr
                end
              else
                exclution_value1 = 0
              end
              
              # 外出時間
              if goout_to <= mid_fr then
                exclution_value2 = 0
              elsif goout_fr <= mid_fr then
                if goout_to <= mid_to then
                  exclution_value2 = goout_to - mid_fr
                else
                  exclution_value2 = 7 * 60 * 60
                end
              elsif goout_fr <= mid_to then
                if goout_to <= mid_to then
                  exclution_value2 = goout_to - goout_fr
                else
                  exclution_value2 = mid_to - goout_fr
                end
              else
                exclution_value2 = 0
              end
            
            end
          end

          if prescribed_to <= mid_fr then
            mid_value1 = 0
          elsif prescribed_fr <= mid_fr then
            if prescribed_to <= mid_to then
              # mid_fr~prescribed_toをベースに休憩、外出を除外
              mid_value1 = (prescribed_to - mid_fr) - exclution_value1 - exclution_value2
            else
              # 深夜時間帯フルをベースに休憩、外出を除外
              mid_value1 = (7 * 60 * 60) - exclution_value1 - exclution_value2
            end
          elsif prescribed_fr <= mid_to then
            if prescribed_to <= mid_to then
              # prescribed_fr~prescribed_toをベースに休憩、外出を除外
              mid_value1 = (prescribed_to - prescribed_fr) - exclution_value1 - exclution_value2
            else
              # prescribed_fr~mid_toをベースに休憩、外出を除外
              mid_value1 = (mid_to - prescribed_fr) - exclution_value1 - exclution_value2
            end
          else
            mid_value1 = 0
          end
        end

        # 時間外における深夜時間の計算
        if daily_params[:over_frh].present? then
          if daily_params[:rest_frh].present? then
            # 休憩がある場合、休憩時間を除外として算定
            if rest_to <= mid_fr then
              exclution_value3 = 0
            elsif rest_fr <= mid_fr then
              if rest_to <= mid_to then
                exclution_value3 = rest_to - mid_fr
              else
                exclution_value3 = 7 * 60 * 60
              end
            elsif rest_fr <= mid_to then
              if rest_to <= mid_to then
                exclution_value3 = rest_to - rest_fr
              else
                exclution_value3 = mid_to - rest_fr
              end
            else
              exclution_value3 = 0
            end          
          end

          if over_to <= mid_fr then
            mid_value2 = 0
          elsif over_fr <= mid_fr then
            if over_to <= mid_to then
            # mid_fr~over_toをベースに休憩を除外
            mid_value2 = (over_to - mid_fr) - exclution_value3
            else
              # 深夜時間帯フルをベースに休憩、外出を除外
              mid_value2 = (7 * 60 * 60) - exclution_value3
            end
          elsif over_fr <= mid_to then
            if over_to <= mid_to then
              # over_fr~over_toをベースに休憩を除外
              mid_value2 = (over_to - over_fr) - exclution_value3
            else
              # over_fr~mid_toをベースに休憩、外出を除外
              mid_value2 = (mid_to - over_fr) - exclution_value3
            end
          else
            mid_value2 = 0
          end
  
        else
          # 時間外がなければ深夜対象なし
          mid_value2 = 0
        end

        mid_value = mid_value1 + mid_value2
        m_sec = mid_value % 60
        m_min = ((mid_value - m_sec) / 60) % 60
        m_hr = (mid_value - m_sec - m_min * 60) / (60 ** 2)
        daily.midnight_h = m_hr.to_i
        daily.midnight_m = m_min.to_i

      end
      daily.save!
    end

    render json: { status: 200, message: "Update Success!" }

  rescue => e

    render json: { status: 500, message: "Update Error" }

  end

  # 状態のみ更新
  def status_update
    ActiveRecord::Base.transaction do
      daily = Dailyreport.find(params[:id])
      daily.status = daily_params[:status]
      daily.save!
    end

    render json: { status:200, message: "Update Success!" }

  rescue => e

    render json: { status:500, message: "Update Error"}

  end

  # 承認更新
  def approval_update
    ActiveRecord::Base.transaction do
      daily_params[:approvals].map do |daily_param|
        daily = Dailyreport.find(daily_param[:id])
        daily.approval_id = daily_param[:approval_id]
        daily.approval_date = Date.today
        daily.status = "承認済"
        daily.save!
      end
    end

    render json: { status:200, message: "Update Success!" }

  rescue => e

    render json: { status:500, message: "Update Error"}

  end

  # 承認取消更新
  def approval_cancel
    ActiveRecord::Base.transaction do
      daily_params[:approvals].map do |daily_param|
        daily = Dailyreport.find(daily_param[:id])
        daily.approval_id = nil
        daily.approval_date = nil
        daily.status = "承認取消"
        daily.save!
      end
    end

    render json: { status:200, message: "Update Success!"}

  rescue => e

    render json: { status:500, message: "Update Error"}

  end

  private
  def daily_params
    params.permit(:id, :employee_id, :ym, :date, :kbn, :kbn_reason, 
                          :prescribed_frh, :prescribed_frm, :prescribed_toh, :prescribed_tom, 
                          :lunch_frh, :lunch_frm, :lunch_toh, :lunch_tom, 
                          :over_reason, :over_frh, :over_frm, :over_toh, :over_tom, 
                          :rest_frh, :rest_frm, :rest_toh, :rest_tom, 
                          :late_reason, :late_h, :late_m,
                          :goout_reason, :goout_frh, :goout_frm, :goout_toh, :goout_tom,
                          :early_reason, :early_h, :early_m,
                          :prescribed_h, :prescribed_m, :over_h, :over_m, :midnight_h, :midnight_m,
                          :status, :approval_id, :approval_date, approvals: [:id, :approval_id])
  end

  def getTime2(h,m)
    hm = format("%02<number>d", number: h.to_i) + format("%02<number>d", number: m.to_i)
    if hm <= "2400" then
      retTime= Time.local(2022,1,1,h.to_i,m.to_i,00)
    else
      retTime= Time.local(2022,1,2,h.to_i,m.to_i,00)
    end
    return retTime
  end

  def getTime(h,m)
    addDay = (h.to_i).div(24)
    int_h = (h.to_i) % 24
    return Time.local(2022,1,1+addDay,int_h,m.to_i,00)
  end

  def getTime1(h,m)
    retTime= Time.local(2022,1,1,h.to_i,m.to_i,00)
  end
end
