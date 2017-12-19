class LinkCheckReportsController < ApplicationController
  def create
    service = LinkCheckReport::CreateService.new(
      user: current_user,
      manual_id: link_reportable_params[:manual_id],
      section_id: link_reportable_params[:section_id]
    )

    service.call

    head :created
  end

private

  def link_reportable_params
    params.require(:link_reportable).permit(:manual_id, :section_id)
  end
end
