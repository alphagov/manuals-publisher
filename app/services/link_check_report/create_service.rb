require "services"
require "govspeak/link_extractor"

class LinkCheckReport::CreateService
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
    link_report = call_link_checker_api

    report = LinkCheckReport.new(
      batch_id: link_report.fetch(:batch_id),
      completed_at: link_report.fetch(:completed_at),
      status: link_report.fetch(:status),
      manual_id: manual_id,
      section_id: section_id,
      links: link_report.fetch(:links).map { |link| map_link_attrs(link) }
    )

    report.save!
  rescue Mongoid::Errors::Validations => e
    raise InvalidReport.new(e)
  end

private

  attr_reader :user, :manual_id, :section_id

  def is_for_section?
    section_id.present?
  end

  def link_reportable
    if is_for_section?
      manual = Manual.find(manual_id, user)
      Section.find(manual, section_id)
    else
      Manual.find(manual_id, user)
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
