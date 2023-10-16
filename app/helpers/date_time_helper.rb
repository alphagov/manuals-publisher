module DateTimeHelper
  def nice_time_format(time)
    tag.time datetime: time.iso8601 do
      time.strftime("%l:%M%P on %-d %B %Y")
    end
  end
end
