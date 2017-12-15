class LinkCheckReportsController < ApplicationController
  def create
    service = LinkCheckReport::CreateService.new(
      user: current_user,
      link_reportable_type: link_reportable_params[:type],
      link_reportable_id: link_reportable_params[:id]
    )

    service.call

    head :created
  end

private

  def link_reportable_params
    params.require(:link_reportable).permit(:type, :id)
  end
end
