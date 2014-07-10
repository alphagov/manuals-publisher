class AaibImportMapper
  def initialize(document_creator)
    @document_creator = document_creator
  end

  def call(raw_data)
    document_creator.call(
      massage(raw_data)
        .slice(*desired_keys)
        .symbolize_keys
    )
  end

private
  attr_reader :document_creator

  def massage(data)
    data.merge({
      "summary" => "TODO: Figure out summary", # Temporary till we figure out what *should* go here.
      "report_type" => report_type(data),
    })
  end

  def report_type(data)
    case data["report_type"]
    when "bulletin" then "special-bulletins"
    when "special bulletin" then "special-bulletins"
    when "formal report" then "formal-reports"
    else raise "Unknown report type: #{data["report_type"]}"
    end
  end

  def desired_keys
    %w(
      title
      summary
      registration_string
      date_of_occurrence
      registrations
      aircraft_categories
      report_type
      location
      aircraft_types
      body
    )
  end
end
