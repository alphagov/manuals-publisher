Then(/^the HTML is converted to govspeak$/) do
  textareas = page.all(".js-paste-html-to-govspeak")
  def synthetic_paste(textarea, clipboard)
    # Create a temporary element to hold the clipboard content.
    temp_element = Nokogiri::HTML.fragment(clipboard)

    # Get the content of the temporary element.
    content = temp_element.text

    # Clear the textarea.
    textarea.value = ""

    # Insert the content into the textarea.
    textarea.value += content
  end

  textareas.each do |textarea|
    synthetic_paste(textarea, "<h1>Title</h1>")
    expect(textarea.value).must_equal "## Title"
  end
end
