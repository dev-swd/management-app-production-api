class Api::V1::QualitygoalsController < ApplicationController
  def show
    render json: Qualitygoal.find(params[:id])
  end

  def create
    goal = Qualitygoal.new(goal_params)
    if goal.save
      render json: goal
    else
      render json: { status: 500, goal: goal}
    end
  end

  def update
    goal = Qualitygoal.find(params[:id])
    if goal.update(goal_params)
      render json: goal
    else
      render json: { status: 500, goal: goal}
    end
  end

  def destroy
    goal = Qualitygoal.find(params[:id])
    goal.destroy
    render json: goal
  end

  private
  def goal_params
    params.require(:qualitygoal).permit(:project_id, :number, :contents)
  end
end
