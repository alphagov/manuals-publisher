class CmaCase < Document
  def self.extra_field_names
    [
      :opened_date,
      :closed_date,
      :case_type,
      :case_state,
      :market_sector,
      :outcome_type,
    ]
  end

  extra_field_names.each do |field_name|
    define_method(field_name) do
      document.extra_fields.fetch(field_name, nil)
    end
  end
end
