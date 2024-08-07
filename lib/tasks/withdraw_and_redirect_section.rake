require "csv"

desc "Withdraw and redirect section, e.g withdraw_and_redirect_section['guidance/manual/section,/redirect/blah,true']"
task :withdraw_and_redirect_section, %i[section_path redirect discard_draft] => :environment do |_, args|
  discard_draft = args.fetch(:discard_draft) == "true"
  redirect_section(args.fetch(:section_path), args.fetch(:redirect), discard_draft)
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
    redirect_section(section_path, "/#{base_path}", true)
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

desc "bulk archive sections, e.g bulk_archive_sections['lib/tasks/data/archive_sections.csv']"
task :bulk_archive_sections, %i[csv_path] => :environment do |_, args|
  section_count = CSV.read(args.fetch(:csv_path), headers: true).length
  puts "Archiving #{section_count} sections..."

  failures = {}
  CSV.foreach(args.fetch(:csv_path), headers: true) do |row|
    section_path = row["section_path"]
    edition = SectionEdition.find_by(slug: section_path)
    edition.state = "archived"
    edition.save!
    print "."
  rescue StandardError => e
    print "x"
    failures[section_path] = e
  end
  puts "\ndone"

  failures.each do |section_path, exception|
    puts "unable to archive #{section_path} due to #{exception.message}"
    puts "=" * 10
  end
end

def redirect_section(section_path, redirect, discard_draft)
  redirect_section = WithdrawAndRedirectSection.new(
    user: User.gds_editor,
    section_path:,
    redirect:,
    discard_draft:,
  )
  redirect_section.execute
end
