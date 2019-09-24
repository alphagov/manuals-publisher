class LinkCheckReportsController < ApplicationController
  def create
    service = LinkCheckReport::CreateService.new(
      user: current_user,
      manual_id: link_reportable_params[:manual_id],
      section_id: link_reportable_params[:section_id],
    )

    @report = service.call

    return handle_nil_report unless @report

    @reportable = reportable_hash

    respond_to do |format|
      format.js { render "admin/link_check_reports/create" }
      format.html { redirect_to_reportable_path }
    end
  end

  def show
    @report = LinkCheckReport::ShowService.new(
      id: link_reportable_show_params[:id],
    ).call

    @reportable = reportable_hash

    respond_to do |format|
      format.js { render "admin/link_check_reports/show" }
      format.html { redirect_to_reportable_path }
    end
  end

private

  def handle_nil_report
    respond_to do |format|
      format.js { head :unprocessable_entity }
      format.html { redirect_back(fallback_location: root_path) }
    end
  end

  def reportable_object
    @reportable_object ||= find_reportable(section_id: @report.section_id, manual_id: @report.manual_id)
  end

  def link_reportable_params
    params.require(:link_reportable).permit(:manual_id, :section_id)
  end

  def link_reportable_show_params
    params.permit(:id)
  end

  def find_reportable(reportable_params)
    LinkCheckReport::FindReportableService.new(
      user: current_user,
      manual_id: reportable_params[:manual_id],
      section_id: reportable_params[:section_id],
    ).call
  end

  def redirect_to_reportable_path
    if reportable_object.is_a?(Section)
      redirect_to manual_section_path(reportable_object.manual.to_param, reportable_object.to_param)
    elsif reportable_object.is_a?(Manual)
      redirect_to manual_path(reportable_object.to_param)
    end
  end

  def reportable_hash
    { section_id: @report.section_id,
      manual_id: @report.manual_id }.delete_if { |_, v| v.blank? }
  end
end
