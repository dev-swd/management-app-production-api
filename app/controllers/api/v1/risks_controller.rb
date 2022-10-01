class Api::V1::RisksController < ApplicationController
  def show
    render json: Risk.find(params[:id])
  end

  def create
    rsk = Risk.new(rsk_params)
    if rsk.save
      render json: rsk
    else
      render json: { status: 500, rsk: rsk}
    end
  end

  def update
    rsk = Risk.find(params[:id])
    if rsk.update(rsk_params)
      render json: rsk
    else
      render json: { status: 500, rsk: rsk}
    end
  end

  def destroy
    rsk = Risk.find(params[:id])
    rsk.destroy
    render json: rsk
  end

  private
  def rsk_params
    params.require(:risk).permit(:project_id, :number, :contents)
  end

end
