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
    link_report = call_link_checker_api.deep_symbolize_keys

    report = LinkCheckReport.new(
      batch_id: link_report.fetch(:id),
      completed_at: link_report.fetch(:completed_at),
      status: link_report.fetch(:status),
      manual_id: manual_id,
      section_id: section_id,
      links: link_report.fetch(:links).map { |link| map_link_attrs(link) }
    )

    report.save!

    report
  rescue Mongoid::Errors::Validations => e
    raise InvalidReport.new(e)
  end

private

  attr_reader :user, :manual_id, :section_id

  def manual
    @manual ||= Manual.find(manual_id, user)
  end

  def section
    raise "Not a section" unless is_for_section?
    @section ||= Section.find(manual, section_id)
  end

  def is_for_section?
    section_id.present?
  end

  def link_reportable
    if is_for_section?
      section
    else
      manual
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
