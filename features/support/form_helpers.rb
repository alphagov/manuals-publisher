module FormHelpers
  def fill_in_fields(names_and_values)
    names_and_values.each do |field_name, value|
      fill_in_field(field_name, value)
    end
  end

  def fill_in_field(field_name, value)
    label_text = field_name.to_s.humanize

    if page.has_css?("select[text='#{label_text}']")
      select value, from: label_text
    else
      fill_in label_text, with: value
    end
  end

  def clear_datetime(label)
    base_dom_id = find(:xpath, ".//label[contains(., '#{label}')]")["for"].gsub(/(_[1-5]i)$/, "")

    find(:xpath, ".//select[@id='#{base_dom_id}_1i']").select("")
    find(:xpath, ".//select[@id='#{base_dom_id}_2i']").select("")
    find(:xpath, ".//select[@id='#{base_dom_id}_3i']").select("")

    find(:xpath, ".//select[@id='#{base_dom_id}_4i']").select("")
    find(:xpath, ".//select[@id='#{base_dom_id}_5i']").select("")
  end
end

RSpec.configuration.include FormHelpers, type: :feature
World(FormHelpers) if respond_to?(:World)
