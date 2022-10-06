desc "Withdraw and redirect section, e.g withdraw_and_redirect_section['guidance/manual,guidance/manual/section,/redirect/blah,true']"
task :withdraw_and_redirect_section, %i[manual_path section_path redirect discard_draft] => :environment do |_, args|
  discard_draft = args.fetch(:discard_draft) == "true"

  redirect_section = WithdrawAndRedirectSection.new(
    user: User.gds_editor,
    manual_path: args.fetch(:manual_path),
    section_path: args.fetch(:section_path),
    redirect: args.fetch(:redirect),
    discard_draft:,
  )

  redirect_section.execute

  puts "Section withdrawn and redirected to #{args.fetch(:redirect)}"
end
