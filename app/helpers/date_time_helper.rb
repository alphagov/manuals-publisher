module DateTimeHelper

  def nice_time_format(time)
    content_tag :time, datetime: time.iso8601 do
      time.strftime("%I:%M%P on %-d %B %Y")
    end
  end

end
