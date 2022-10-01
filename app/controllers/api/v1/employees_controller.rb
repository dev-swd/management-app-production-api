class Api::V1::EmployeesController < ApplicationController

  # 社員一覧取得（全件）
  def index
    emps = Employee
            .joins("LEFT OUTER JOIN users ON users.id=devise_id")
            .joins("LEFT OUTER JOIN divisions AS divs ON divs.id=division_id LEFT OUTER JOIN departments AS deps ON deps.id=divs.department_id")
            .select("employees.*, divs.code as div_code, divs.name as div_name, deps.id as department_id, deps.code as dep_code, deps.name as dep_name, users.name as devise_name")
            .order(:number)
    render json: { status: 200, emps: emps }
  end

  # 社員情報新規登録
  def create
    emp = Employee.new(emp_params)
    if emp.save then
      render json: { status:200, message: "Insert Success!", emp: emp }
    else
      render json: { status:500, message: "Insert Error"}
    end
  end

  # 社員情報新規登録（システム管理者用）
  def create_with_password
    if emp_params[:systempwd] == "]r@tdef[r0¥s@" || emp_params[:systempwd] == "]r@tdef[r0\s@" then
      emp = Employee.new()
      emp.number = emp_params[:number]
      emp.name = emp_params[:name]
      emp.joining_date = emp_params[:joining_date]
      emp.authority = emp_params[:authority]
      if emp.save then
        render json: { status:200, message: "Insert Success!", emp: emp }
      else
        render json: { status:500, message: "Insert Error"}
      end
    else
      render json: { status:400, message: "Incorrect password"}
    end
end

  # 社員情報更新（ID指定）
  def update
    emp = Employee.find(params[:id])
    if emp.update(emp_params)
      render json: { status: 200, message: "Update Success!", emp: emp }
    else
      render json: { status: 500, message: "Update Error" }
    end
  end

  # 社員一覧取得（課ID指定）
  def index_by_div
    emps = Division
      .joins(:department, :employees)
      .select("departments.name AS dep_name, divisions.name As div_name, employees.*")
      .where(id: params[:id])
      .order("employees.number")
    render json: { status: 200, emps: emps }
  end

  # 社員一覧取得（事業部直轄=事業部ID指定）
  def index_by_dep_direct
    emps = Division
      .joins(:employees)
      .select("employees.*")
      .where(department_id: params[:id])
      .where(code: 'dep')
      .order("employees.number")
    render json: { status: 200, emps: emps }
  end

  # 社員一覧取得（未所属）
  def index_by_not_assign
    emps = Employee
      .joins("LEFT OUTER JOIN users ON users.id=devise_id")
      .select("employees.*, users.name as devise_name")
      .where(division_id: nil)
      .order("employees.number")
    render json: { status: 200, emps: emps }
  end

  # 社員情報詳細 with Devise情報（emp_id指定）
  def show_with_devise
    emp = Employee
          .joins("LEFT OUTER JOIN users ON users.id=devise_id")
          .joins("LEFT OUTER JOIN divisions AS divs ON divs.id=division_id LEFT OUTER JOIN departments AS deps ON deps.id=divs.department_id")
          .select("employees.*, divs.code as div_code, divs.name as div_name, deps.id as department_id, deps.code as dep_code, deps.name as dep_name, users.name as devise_name")
          .find(params[:id])
    render json: { status: 200, emp: emp }
  end

  # 社員情報詳細（devise_id指定）
  def show_by_devise
    emp = Employee
          .joins("LEFT OUTER JOIN divisions AS divs ON divs.id=division_id LEFT OUTER JOIN departments AS deps ON deps.id=divs.department_id")
          .select("employees.*, divs.code as div_code, divs.name as div_name, deps.id as department_id, deps.code as dep_code, deps.name as dep_name")
          .find_by(devise_id: params[:id]);
    if emp.present? then
      render json: { status: 200, emp: emp }
    else
      render json: { status: 500, message: "No Data"}
    end
  end

  # Deviseパスワード変更(empId指定／password有)
  def update_password_with_currentpassword
    emp = Employee.find(params[:id]);
    user = User.find(emp.devise_id)
    if user.update_with_password(
      password: emp_params[:password],
      password_confirmation: emp_params[:password_confirmation],
      current_password: emp_params[:current_password]
    ) then
      render json: { status: 200, message: "Update Success!" }
    else
      render json: { status: 500, message: "Update Error" }
    end
  end

  # Deviseパスワード変更(empId指定／password無)
  def update_password_without_currentpassword
    emp = Employee.find(params[:id]);
    user = User.find(emp.devise_id)
    if user.update_without_current_password(
      password: emp_params[:password],
      password_confirmation: emp_params[:password_confirmation],
    ) then
      render json: { status: 200, message: "Update Success!" }
    else
      render json: { status: 500, message: "Update Error" }
    end
  end

  # 社員情報詳細（社員ID指定）
  def show
    emp = Employee
          .joins("LEFT OUTER JOIN divisions AS divs ON divs.id=division_id LEFT OUTER JOIN departments AS deps ON deps.id=divs.department_id")
          .select("employees.*, divs.name as div_name, deps.name as dep_name")
          .find(params[:id])
    render json: { status: 200, emp: emp }
  end

  # 承認対象社員検索
  def index_by_approval
    emps = Division
      .joins(:department, :employees, :approvalauths)
      .select("departments.name AS dep_name, divisions.name As div_name, employees.*")
      .where("approvalauths.employee_id = ?", params[:id]).order("employees.number")
      .order("employees.number")
    render json: { status: 200, emps: emps }
  end

  # 社員情報削除（社員ID指定）
  def destroy
    emp = Employee.find(params[:id])
    emp.destroy
    render json: { status: 200, message: "Destroy Success" }
  end

    
# ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑ 再確認済

  # devise user一覧
  def index_devise
    users = User.all.order(:id)
    render json: { status: 200, users: users }
  end



# 改訂前
#  def index
#    render json: Employee.joins("LEFT OUTER JOIN divisions AS divs ON divs.id=division_id LEFT OUTER JOIN departments AS deps ON deps.id=divs.department_id").select("employees.*, divs.name as div_name, deps.name as dep_name").all.order(:number)
#  end

#def create
##    emp = Employee.new(emp_params)
##    if emp.save
##      render json: emp
##    else
##      render json: {status: 500, messages: emp.errors }
##    end
#    emp = Employee.create(emp_params)
#    if emp.id.present? then
#      render json: { status: 200, emp: emp }
#    else
#      render json: {status: 500, message: "Create Error" }
#    end
#  end

  private
  # ストロングパラメータ
  def emp_params
    params.permit(:number, :name, :name2, :birthday, :address, :phone, :joining_date, :division_id, :devise_id, :authority, :current_password, :password, :password_confirmation, :systempwd)
#    params.permit(:number, :name, :name2, :birthday, :address, :phone, :joining_date, :division_id, :devise_id, :authority)
##    params.require(:employee).permit(:number, :name, :name2, :birthday, :address, :phone, :joining_date, :division_id, :devise_id, :authority)
  end

end
