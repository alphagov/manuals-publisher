class ChangeHistoryController < ApplicationController
  def index
    manual_record = ManualRecord.find_by(manual_id: params[:manual_id])
    @manual = Manual.build_manual_for(manual_record)
    @publication_logs = @manual.publication_logs.reverse
  end
end
