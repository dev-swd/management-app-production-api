class Api::V1::DivisionsController < ApplicationController
  def index
    render json: Division.joins(:department).select("departments.code AS dep_code, departments.name AS dep_name, divisions.*").order("departments.code, divisions.code")
  end

  # 課情報取得（ID指定）
  def show
    div = Division
      .joins(:department)
      .select("departments.code AS dep_code, departments.name AS dep_name, divisions.*")
      .find(params[:id])
    render json: { status: 200, div: div }
  end

  # 課情報新規登録
  def create
    div = Division.new(div_params)
    if div.save
      render json: { status: 200, message: "Insert Success!", div: div }
    else
      render json: { status: 500, message: "Insert Error" }
    end
  end

  # 課情報更新（ID指定）
  def update
    div = Division.find(params[:id])
    if div.update(div_params)
      render json: { status: 200, message: "Update Success!", div: div }
    else
      render json: { status: 500, message: "Update Error" }
    end
  end
    
  # 課情報削除（ID指定）
  def destroy
    ActiveRecord::Base.transaction do
      div = Division.find(params[:id])
      div.destroy!
    end
    render json: { status:200, message: "Delete Success!" }
  rescue => e
    render json: { status:500, message: "Delete Error"}

  end

  # 課情報一覧（事業部ID指定／事業部ダミー課は除外）
  def index_by_department
    divs = Division
      .joins(:department)
      .select("departments.code AS dep_code, departments.name AS dep_name, divisions.*")
      .where(department_id: params[:id])
      .where.not(code: 'dep')
      .order(:code)
    render json: { status: 200, divs: divs }
  end

  # 課情報取得（事業部ダミー課1件のみ／事業部ID指定）
  def show_by_depdummy
    div = Division.find_by(department_id: params[:id], code: 'dep')
    render json: { status: 200, div: div }
  end

#  def show
#    div = Division.joins(:department).select("departments.code AS dep_code, departments.name AS dep_name, divisions.*").find(params[:id])
#    auths = Approvalauth.joins("LEFT OUTER JOIN employees AS emps ON emps.id=employee_id").select("approvalauths.*,emps.name as emp_name").order("emps.number")
#    render json: { status: 200, div: div, auths: auths }
#  end
    
#  def create
#    ActiveRecord::Base.transaction do
#      div = Division.new
#      div.department_id = div_params[:department_id]
#      div.code = div_params[:code]
#      div.name = div_params[:name]
#      div.save!
#      div_params[:auths].map do |auth_param|
#        if auth_param[:del]=false then
#          auth = Approvalauth.find_or_initialize_by(id: auth_param[:id])
#          auth.division_id = params[:id]
#          auth.employee_id = auth_param[:emp_id]
#          auth.save!
#        else
#          if auth_param[:id].blank? then
#          else
#            auth = Approvalauth.find(auth_param[:id])
#            auth.destroy!
#          end
#        end
#      end
#    end
#
#    render json: { status: 200, message: "Insert Success!" }
#
#  rescue => e
#
#    render json: { status: 500, message: "Insert Error"}
#
#  end

#  def update
#    ActiveRecord::Base.transaction do
#
#      div_param = div_params[:div]
#      div = Division.find_or_initialize_by(id: div_param[:id])
#      div.department_id = div_param[:department_id]
#      div.code = div_param[:code]
#      div.name = div_param[:name]
#      div.save!
#
#      div_params[:auths].map do |auth_param|
#        if auth_param[:del]===false then
#          auth = Approvalauth.find_or_initialize_by(id: auth_param[:id])
#          auth.division_id = div.id
#          auth.employee_id = auth_param[:emp_id]
#          auth.save!
#        else
#          if auth_param[:id].blank? then
#          else
#            auth = Approvalauth.find(auth_param[:id])
#            auth.destroy!
#          end
#        end
#      end
#    end
#
#    render json: { status: 200, message: "Update Success!" }
#
#  rescue => e
#
#    render json: { status: 500, message: "Update Error"}
#
#  end


  def index_with_authcnt
    divs = Division
      .joins("LEFT OUTER JOIN departments AS deps ON deps.id=department_id")
      .joins("LEFT OUTER JOIN approvalauths AS auths ON auths.division_id=divisions.id")
      .select("deps.code AS dep_code, deps.name AS dep_name, divisions.id, divisions.code, divisions.name, count(auths.id) AS auth_cnt")
      .group("dep_code, dep_name, divisions.id, divisions.code, divisions.name")
      .order("dep_code, divisions.code")
    render json: { status: 200, divs: divs }
  end
  
  def index_by_approval
    divisions = Division
      .joins(:department, :approvalauths)
      .select("departments.code AS dep_code, departments.name AS dep_name, divisions.*")
      .where("approvalauths.employee_id = ?", params[:id])
      .order("departments.code, divisions.code")
    render json: { status: 200, divs: divisions}
  end

  private
  # ストロングパラメータ
  def div_params
    params.permit(:code, :name, :department_id)
#    params.permit(div: [:id, :code, :name, :department_id], auths: [:id, :emp_id, :emp_name, :del])
  end

end
