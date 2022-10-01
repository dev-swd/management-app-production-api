class Api::V1::ApprovalauthsController < ApplicationController

  def index
    auth = Approvalauth.joins("LEFT OUTER JOIN employees AS emps ON emps.id=employee_id LEFT OUTER JOIN divisions AS divs ON divs.id=division_id LEFT OUTER JOIN departments AS deps ON deps.id=divs.department_id").select("approvalauths.*,emps.number AS emp_no,emps.name AS emp_name, deps.number AS dep_no, deps.name AS dep_name, divs.number AS div_no, divs.name AS div_name").order("emp_no,dep_no,div_no")
    render jeson: { status: 200, auth: auth }
  end

##　上記、未使用　＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊＊

  # 承認権限一覧（課ID指定）
  def index_by_division
    auths = Approvalauth
              .joins(:employee)
              .select("employees.number AS emp_number, employees.name AS emp_name, approvalauths.*")
              .where(division_id: params[:id])
              .order("employees.number")
    render json: { status: 200, auths: auths }
  end

  # 承認権限一覧（事業部直轄=事業部ID指定）
  def index_by_dep_direct
    auths = Division
              .joins(approvalauths: :employee)
              .select("employees.number AS emp_number, employees.name AS emp_name, approvalauths.*")
              .where(department_id: params[:id])
              .where(code: 'dep')
              .order("employees.number")
    render json: { status: 200, auths: auths }
  end

  # 承認権限登録
  def create
    auth = Approvalauth.new(auth_params)
    if auth.save
      render json: { status: 200, message: "Insert Success!" }
    else
      render json: {status: 500, message: "Insert Error" }
    end
  end

  # 削除（ID指定）
  def destroy
    ActiveRecord::Base.transaction do
      auth = Approvalauth.find(params[:id])
      auth.destroy!
    end
    render json: { status:200, message: "Delete Success!" }
  rescue => e
    render json: { status:500, message: "Delete Error"}
  end

  private
  # ストロングパラメータ
  def auth_params
    params.permit(:employee_id, :division_id)
  end

end

