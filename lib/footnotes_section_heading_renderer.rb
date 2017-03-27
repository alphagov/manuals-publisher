class FootnotesSectionHeadingRenderer < SimpleDelegator
  def self.create
    ->(doc) {
      FootnotesSectionHeadingRenderer.new(doc)
    }
  end

  def body
    section.body.gsub(footnote_open_tag, "#{heading_tag}\\&")
  end

  def attributes
    section.attributes.merge(
      body: body,
    )
  end

private

  def footnote_open_tag
    '<div class="footnotes">'
  end

  def heading_tag
    '<h2 id="footnotes">Footnotes</h2>'
  end

  def section
    __getobj__
  end
end
