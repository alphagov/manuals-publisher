desc "Withdraw and redirect manual to multiple paths, e.g withdraw_and_redirect_sections_to_multiple_paths['lib/tasks/tmp_redirect.csv,true']"
task :withdraw_and_redirect_manuals_to_multiple_paths, %i[csv_path discard_drafts] => :environment do |_, args|
  discard_drafts = args.fetch(:discard_drafts) == "true"

  WithdrawAndRedirectToMultiplePaths.new(
    csv_path: args.fetch(:csv_path), discard_drafts: discard_drafts,
  ).execute
end
