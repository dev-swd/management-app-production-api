class Api::V1::MembersController < ApplicationController
  def show
    render json: Member.find(params[:id])
  end

  def create
    mem = Member.new(mem_params)
    if mem.save
      render json: mem
    else
      render json: { status: 500, mem: mem}
    end
  end

  def update
    mem = Member.find(params[:id])
    if mem.update(mem_params)
      render json: mem
    else
      render json: { status: 500, mem: mem}
    end
  end

  def destroy
    mem = Member.find(params[:id])
    mem.destroy
    render json: mem
  end

  private
  def mem_params
    params.require(:member).permit(:project_id, :number, :level, :member_id, :tag)
  end

end
