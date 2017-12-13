module Govspeak
  class LinkExtractor
    def initialize(govspeak)
      @govspeak = govspeak
    end

    def links
      @links ||= extract_links
    end

  private

    def extract_links
      processed_govspeak.css('a:not([href^="mailto"])').css('a:not([href^="#"])').map { |link| link['href'] }
    end

    def processed_govspeak
      doc = Nokogiri::HTML::Document.new
      doc.encoding = "UTF-8"

      doc.fragment(Govspeak::Document.new(@govspeak).to_html)
    end
  end
end
