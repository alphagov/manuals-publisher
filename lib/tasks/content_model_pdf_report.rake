require "csv"

desc "Generate content model PDF report"
task content_model_pdf_report: :environment do
  first_period_start_date = ENV.fetch("FIRST_PERIOD_START_DATE", Date.parse("2016-01-01"))
  last_time_period_days = ENV.fetch("LAST_TIME_PERIOD_DAYS", 30)

  attachment_reporter = AttachmentReporting.new(first_period_start_date, last_time_period_days, "pdf")

  organisation_attachment_count_hash = attachment_reporter.create_organisation_attachment_count_hash

  CSV($stdout) do |document_csv|
    document_csv << [
      "Organisation",
      "Total published PDF attachments",
      "#{first_period_start_date} - present PDF attachments",
      "Last #{last_time_period_days} days PDF attachments",
    ]

    organisation_attachment_count_hash.each_pair do |organisation_name, pdf_count_array|
      document_csv << [
        organisation_name,
        pdf_count_array[0],
        pdf_count_array[1],
        pdf_count_array[2],
      ]
    end
  end
end
