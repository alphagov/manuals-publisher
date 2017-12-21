class LinkCheckReportsController < ApplicationController
  def create
    service = LinkCheckReport::CreateService.new(
      user: current_user,
      manual_id: link_reportable_params[:manual_id],
      section_id: link_reportable_params[:section_id]
    )

    @report = service.call

    @reportable = find_reportable(link_reportable_params)

    respond_to do |format|
      format.js { render 'admin/link_check_reports/create' }
      format.html { redirect_to_reportable }
    end
  end

  def show
    @report = LinkCheckReport::ShowService.new(
      id: link_reportable_show_params[:id]
    ).call

    @reportable = find_reportable(section_id: @report.section_id, manual_id: @report.manual_id)

    respond_to do |format|
      format.js { render 'admin/link_check_reports/show' }
      format.html { redirect_to_reportable }
    end
  end

private

  def link_reportable_params
    params.require(:link_reportable).permit(:manual_id, :section_id)
  end

  def link_reportable_show_params
    params.permit(:id)
  end

  def find_reportable(reportable_params)
    if reportable_params[:section_id] && reportable_params[:manual_id]
      manual = Manual.find(reportable_params[:manual_id], current_user)
      Section.find(manual, reportable_params[:manual_id])
    elsif reportable_params[:manual_id]
      Manual.find(reportable_params[:manual_id], current_user)
    end
  end

  def redirect_to_reportable
    if @reportable.is_a?(Section)
      redirect_to manual_section_path(@reportable.manual.to_param, @reportable.to_param)
    elsif @reportable.is_a?(Manual)
      redirect_to manual_path(@reportable.to_param)
    end
  end
end
