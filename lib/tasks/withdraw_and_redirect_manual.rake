require "thor"

def shell
  @shell ||= Thor::Shell::Basic.new
end

desc "Withdraw and redirect manual, e.g withdraw_and_redirect_manual['guidance/manual,/redirect/blah,true,true']"
task :withdraw_and_redirect_manual, %i[manual_path redirect include_sections discard_drafts] => :environment do |_, args|
  discard_drafts = args.fetch(:discard_drafts) == "true"
  include_sections = args.fetch(:include_sections) == "true"
  redirect = args.fetch(:redirect)

  confirmation_message =
    if include_sections
      "You're about to redirect the manual and all its sections to '#{redirect}'. Proceed? (yes/no)"
    else
      "You're about to redirect the manual to '#{redirect}', but the sections will not be redirected (due to `include_sections` argument passed in as false).\nYou must ensure that all of the manual's sections are redirected individually, using the `withdraw_and_redirect_section` rake task.\nProceed? (yes/no)"
    end

  unless shell.yes?(confirmation_message)
    shell.say_error "Aborted"
    next
  end

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
  end
end
