require "services"

class LinkCheckReport::CreateService
  include Rails.application.routes.url_helpers

  CALLBACK_HOST = Plek.find("manuals-publisher")

  class InvalidReport < RuntimeError
    def initialize(original_error)
      @message = original_error.message
    end
  end

  def initialize(user:, manual_id:, section_id: nil)
    @user = user
    @manual_id = manual_id
    @section_id = section_id
  end

  def call
    return if uris.empty?

    link_report = call_link_checker_api.deep_symbolize_keys

    report = LinkCheckReport.new(
      batch_id: link_report.fetch(:id),
      completed_at: link_report.fetch(:completed_at),
      status: link_report.fetch(:status),
      manual_id: manual_id,
      section_id: section_id,
      links: link_report.fetch(:links).map { |link| map_link_attrs(link) },
    )

    report.save!

    report
  rescue Mongoid::Errors::Validations => e
    raise InvalidReport, e
  end

private

  attr_reader :user, :manual_id, :section_id

  def reportable
    @reportable ||= LinkCheckReport::FindReportableService.new(
      user: user,
      manual_id: manual_id,
      section_id: section_id,
    ).call
  end

  def uris
    @uris ||= LinkCheckReport::LinkExtractorService.new(body: reportable.body).call
  end

  def call_link_checker_api
    callback = link_checker_api_callback_url(host: CALLBACK_HOST)

    Services.link_checker_api.create_batch(
      uris,
      webhook_uri: callback,
      webhook_secret_token: Rails.application.secrets.link_checker_api_secret_token,
    )
  end

  def map_link_attrs(link)
    {
      uri: link.fetch(:uri),
      status: link.fetch(:status),
      checked: link.fetch(:checked),
      check_warnings: link.fetch(:warnings, []),
      check_errors: link.fetch(:errors, []),
      problem_summary: link.fetch(:problem_summary),
      suggested_fix: link.fetch(:suggested_fix),
    }
  end
end
