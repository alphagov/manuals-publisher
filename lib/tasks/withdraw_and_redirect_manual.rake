desc "Withdraw and redirect manual, e.g withdraw_and_redirect_manual['guidance/manual,/redirect/blah,true']"
task :withdraw_and_redirect_manual, %i[manual_path redirect discard_drafts] => :environment do |_, args|
  discard_drafts = args.fetch(:discard_drafts) == "true"
  redirect = args.fetch(:redirect)

  redirect_manual = WithdrawAndRedirectManual.new(
    user: User.gds_editor,
    manual_path: args.fetch(:manual_path),
    redirect:,
    discard_drafts:,
  )

  redirect_manual.execute

  puts "Manual and sections withdrawn and redirected to #{redirect}"
end
