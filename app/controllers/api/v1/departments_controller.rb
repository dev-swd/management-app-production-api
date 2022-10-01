class Api::V1::DepartmentsController < ApplicationController

  # 事業部一覧取得（無条件）
  def index
    deps = Department.all.order(:code)
    render json: { status: 200, deps: deps }
  end

  # 事業部取得（ID指定）
  def show
    dep = Department.find(params[:id])
    render json: { status: 200, dep: dep }
  end

  # 事業部新規登録
  def create
#    dep = Department.new(dep_params)
#    if dep.save
#      render json: { status: 200, message: "Insert Success!", dep: dep }
#    else
#      render json: { status: 500, message: "Insert Error" }
#    end
    ActiveRecord::Base.transaction do
      
      #事業部登録
      dep = Department.new(dep_params)
      dep.save!

      #課（ダミー）
      div = Division.new()
      div.department_id = dep.id
      div.code = "dep"
      div.name = dep_params[:name]
      div.save!

    end

    render json: { status: 200, message: "Create Success!" }

  rescue => e

    render json: { status: 500, message: "Create Error" }

  end

  # 事業部更新（ID指定)
  def update
    dep = Department.find(params[:id])
    if dep.update(dep_params)
      render json: { status: 200, message: "Update Success!", dep: dep }
    else
      render json: { status: 500, message: "Update Error" }
    end
  end

  # 事業部削除（ID指定）
  def destroy
    ActiveRecord::Base.transaction do
      dep = Department.find(params[:id])
      dep.destroy!
    end
    render json: { status:200, message: "Delete Success!" }
  rescue => e
    render json: { status:500, message: "Delete Error"}
  end

  private
  # ストロングパラメータ
  def dep_params
    params.permit(:code, :name)
  end

end
