require "csv"

desc "Withdraw and redirect section, e.g withdraw_and_redirect_section['guidance/manual,guidance/manual/section,/redirect/blah,true']"
task :withdraw_and_redirect_section, %i[manual_path section_path redirect discard_draft] => :environment do |_, args|
  discard_draft = args.fetch(:discard_draft) == "true"
  redirect_section(args.fetch(:manual_path), args.fetch(:section_path), args.fetch(:redirect), discard_draft)
  puts "Section withdrawn and redirected to #{base_path}"
end

desc "Withdraw and redirect sections to their manual base path, e.g bulk_withdraw_and_redirect_section_to_manual['lib/tasks/data/withdraw_sections.csv']"
task :bulk_withdraw_and_redirect_section_to_manual, %i[csv_path] => :environment do |_, args|
  section_count = CSV.read(args.fetch(:csv_path), headers: true).length
  puts "Withdrawing and unpublishing #{section_count} sections..."

  failures = {}
  CSV.foreach(args.fetch(:csv_path), headers: true) do |row|
    section_path = row["section_path"]
    base_path = section_path.split("/")[0..1].join("/")
    redirect_section(base_path, section_path, "/#{base_path}", true)
    print "."
  rescue StandardError => e
    print "x"
    failures[section_path] = e
  end
  puts "\ndone"

  failures.each do |section_path, exception|
    puts "unable to withdraw #{section_path} due to #{exception.message}"
    puts "=" * 10
  end
end


def redirect_section(manual_path, section_path, redirect, discard_draft)
  redirect_section = WithdrawAndRedirectSection.new(
    user: User.gds_editor,
    manual_path:,
    section_path:,
    redirect:,
    discard_draft:,
  )
  redirect_section.execute
end
