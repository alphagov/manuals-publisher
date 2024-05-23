class ChangeHistoryController < ApplicationController
  before_action :find_manual
  before_action :authorize_user_for_changing_history

  def index
    @publication_logs = @manual.publication_logs.reverse
  end

private

  def find_manual
    manual_record = ManualRecord.find_by(manual_id: params[:manual_id])
    @manual = Manual.build_manual_for(manual_record)
  end

  def authorize_user_for_changing_history
    unless current_user_can_change_history?
      redirect_to(
        manual_path(@manual.id),
        flash: { error: "You don't have permission to change history." },
      )
    end
  end
end
