require "csv"

desc "Withdraw and redirect section. WARNING: discard_draft will destroy drafts, usage: withdraw_and_redirect_section['guidance/manual/section,/redirect/blah,false']"
task :withdraw_and_redirect_section, %i[section_path redirect discard_draft] => :environment do |_, args|
  discard_draft = args.fetch(:discard_draft) == "true"
  section_path = args.fetch(:section_path)
  redirect = args.fetch(:redirect)

  redirect_section = WithdrawAndRedirectSection.new(
    user: User.gds_editor,
    section_path:,
    redirect:,
    discard_draft:,
  )
  redirect_section.execute
  puts "Section withdrawn and redirected to #{redirect}"
end
