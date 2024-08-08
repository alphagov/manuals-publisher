require "csv"

desc "Withdraw and redirect section. WARNING: discard_draft will destroy drafts, usage: withdraw_and_redirect_section['guidance/manual/section,/redirect/blah,false']"
task :withdraw_and_redirect_section, %i[section_path redirect discard_draft] => :environment do |_, args|
  discard_draft = args.fetch(:discard_draft) == "true"
  redirect_section = WithdrawAndRedirectSection.new(
    user: User.gds_editor,
    section_path:,
    redirect:,
    discard_draft:,
  )
  redirect_section.execute
  puts "Section withdrawn and redirected to #{base_path}"
end

desc "Just redirect sections to their manual base path, e.g bulk_redirect_section_to_manual['lib/tasks/data/withdraw_sections.csv']"
task :bulk_redirect_section_to_manual, %i[csv_path] => :environment do |_, args|
  section_count = CSV.read(args.fetch(:csv_path), headers: true).length
  puts "Withdrawing and unpublishing #{section_count} sections..."

  failures = {}
  CSV.foreach(args.fetch(:csv_path), headers: true) do |row|
    section_path = row["section_path"]
    base_path = section_path.split("/")[0..1].join("/")
    section_edition = SectionEdition.where(slug: section_path).first
    Publishing::RedirectAdapter.redirect_section(section_edition, to: "/#{base_path}")
    print "."
  rescue StandardError => e
    print "x"
    failures[section_path] = e
  end
  puts "\ndone"

  failures.each do |section_path, exception|
    puts "unable to redirect #{section_path} due to #{exception.message}"
    puts "=" * 10
  end
end
