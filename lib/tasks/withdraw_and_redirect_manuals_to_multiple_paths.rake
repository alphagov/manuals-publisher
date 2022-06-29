namespace :withdraw_and_redirect_manuals_to_multiple_paths  do
  desc "Withdraw and redirect manual to multiple paths, e.g withdraw_and_redirect_sections_to_multiple_paths['lib/tasks/tmp_redirect.csv,true']"
  task :real, %i[csv_path discard_drafts] => :environment do |_, args|
    discard_drafts = args.fetch(:discard_drafts) == "true"

    WithdrawAndRedirectToMultiplePaths.new(
      csv_path: args.fetch(:csv_path), discard_drafts: discard_drafts,
    ).execute
  end

  desc "Dry run to check all base_paths in CSV exist"
  task :dry_run, %i[csv_path] => :environment do |_, args|
    missing_paths = WithdrawAndRedirectToMultiplePaths.new(
      csv_path: args.fetch(:csv_path), dry_run: true,
    ).execute

    if missing_paths[:sections].blank? && missing_paths[:manuals].blank?
      puts "PASS - all paths from the CSV exist"
    else
      puts "FAIL - some paths don't exist"

      puts "Missing Manuals: #{missing_paths[:manuals]}"

      puts "Missing Sections: #{missing_paths[:sections]}"
    end
  end
end
