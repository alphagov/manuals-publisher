require "services"
require "govspeak/link_extractor"

class LinkCheckReport::CreateService
  class InvalidReport < RuntimeError
    def initialize(original_error)
      @message = original_error.message
    end
  end

  def initialize(user:, link_reportable_type:, link_reportable_id:)
    @user = user
    @link_reportable_type = link_reportable_type
    @link_reportable_id = link_reportable_id
  end

  def call
    link_report = call_link_checker_api

    report = LinkCheckReport.new(
      batch_id: link_report.fetch(:batch_id),
      completed_at: link_report.fetch(:completed_at),
      status: link_report.fetch(:status),
      link_reportable_type: link_reportable_type,
      link_reportable_id: link_reportable_id,
      links: link_report.fetch(:links).map { |link| map_link_attrs(link) }
    )

    report.save!
  rescue Mongoid::Errors::Validations => e
    raise InvalidReport.new(e)
  end

private

  attr_reader :user, :link_reportable_type, :link_reportable_id

  def link_reportable
    if link_reportable_type == "manual"
      Manual.find(link_reportable_id, user)
    end
  end

  def uris
    Govspeak::LinkExtractor.new(link_reportable.body).links
  end

  def call_link_checker_api
    Services.link_checker_api.create_batch(uris)
  end

  def map_link_attrs(link)
    {
      uri: link.fetch(:uri),
      status: link.fetch(:status),
      checked: link.fetch(:checked),
      check_warnings: link.fetch(:warnings, []),
      check_errors: link.fetch(:errors, []),
      problem_summary: link.fetch(:problem_summary),
      suggested_fix: link.fetch(:suggested_fix)
    }
  end
end
