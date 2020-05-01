require "csv"

namespace :reporting do
  desc "A CSV report of organisation publishing by month. Splits by freshly created and updated content"
  task organisation_publishing_by_month: :environment do
    options = {
      start_date: ENV.fetch("START_DATE", "2016-04-01"),
      end_date: ENV.fetch("END_DATE", "2017-03-31"),
    }

    date_range = Date.parse(options[:start_date])...Date.parse(options[:end_date])
    months = date_range.select { |d| d.day == 1 }.map { |m| "#{m.year}-#{m.month.to_s.rjust(2, '0')}" }

    csv = CSV.open("organisation_publishing_by_month-#{options[:start_date]}-#{options[:end_date]}.csv", "w")
    csv << ([""] + months.map { |m| [m, m] }.flatten)
    csv << (%w[Organisation] + months.size.times.map { |_| %w[Published Updates] }.flatten)

    all_editions = ManualRecord::Edition.where(updated_at: date_range, state: { "$in" => %w[published archived] })

    by_org = all_editions.group_by { |e| e.manual_record.organisation_slug }.sort

    by_org.each do |(org, records)|
      row = [org]
      by_month = records.group_by { |r| "#{r.updated_at.year}-#{r.updated_at.month.to_s.rjust(2, '0')}" }

      months.each do |month|
        created, updated = (by_month[month] || []).partition { |e| e.version_number == 1 }
        row += [created.size, updated.size]
      end
      csv << row
    end
  end
end
