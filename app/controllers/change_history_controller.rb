class ChangeHistoryController < ApplicationController
  before_action :find_manual
  before_action :authorize_user_for_changing_history

  def index
    @publication_logs = @manual.publication_logs.reverse
  end

  def confirm_destroy
    @publication_log = PublicationLog.find(params[:id])
  end

  def destroy
    @publication_log = PublicationLog.find(params[:id])
    @publication_log.destroy!

    Manual::RepublishService.call(
      user: current_user,
      manual_id: @manual.id,
    )

    flash[:success] = "Change note deleted."
    redirect_to manual_change_history_index_path(manual_id: @manual.id)
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
