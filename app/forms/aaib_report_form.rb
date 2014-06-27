class AaibReportForm < DocumentForm
  attributes = [
    :title,
    :summary,
    :body,
    :date_of_occurrence,
    :aircraft_category,
    :report_type,
  ]

  attributes.each do |attribute_name|
    define_method(attribute_name) do
      delegate_if_document_exists(attribute_name)
    end
  end
end
