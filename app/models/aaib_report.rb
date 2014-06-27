class AaibReport < Document
  def self.extra_field_names
    [
      :date_of_occurrence,
      :aircraft_category,
      :report_type,
    ]
  end

  extra_field_names.each do |field_name|
    define_method(field_name) do
      document.extra_fields.fetch(field_name, nil)
    end
  end
end
