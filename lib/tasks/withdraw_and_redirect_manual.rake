desc "Withdraw and redirect manual, e.g withdraw_and_redirect_manual['guidance/manual,/redirect/blah,true,true']"
task :withdraw_and_redirect_manual, %i[manual_path redirect include_sections discard_drafts] => :environment do |_, args|
  discard_drafts = args.fetch(:discard_drafts) == "true"
  include_sections = args.fetch(:include_sections) == "true"
  redirect = args.fetch(:redirect)

  redirect_manual = WithdrawAndRedirectManual.new(
    user: User.gds_editor,
    manual_path: args.fetch(:manual_path),
    redirect:,
    include_sections:,
    discard_drafts:,
  )

  redirect_manual.execute

  if include_sections
    puts "Manual and sections withdrawn and redirected to #{redirect}"
  else
    puts "Manual withdrawn and redirected to #{redirect}"
    puts "The sections have not been redirected because `include_sections` was passed in as false. " \
           "You must ensure that all of the manual's sections are redirected individually, using the " \
           "`withdraw_and_redirect_section` rake task or an alternative approach such as Short URL Manager."
  end
end
