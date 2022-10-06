require "csv"

class WithdrawAndRedirectToMultiplePaths
  def initialize(csv_path:, discard_drafts: false, dry_run: false)
    @csv_path = csv_path
    @discard_drafts = discard_drafts
    @user = User.gds_editor
    @dry_run = dry_run
  end

  def execute
    if dry_run
      missing_paths = { sections: [], manuals: [] }
    end

    grouped_sections_by_manual.each do |manual_path, children|
      children.each do |child|
        next if updates_page?(child["base_path"])

        if manual_path == child["base_path"]
          withdraw_and_redirect_manual(child)
        else
          withdraw_and_redirect_section(child, manual_path)
        end

      rescue WithdrawAndRedirectManual::ManualNotPublishedError
        log("[ERROR] Manual not redirected due to not being in a published state: #{child['base_path']}")
      rescue WithdrawAndRedirectSection::SectionNotPublishedError
        log("[ERROR] Section not redirected due to not being in a published state: #{child['base_path']}")
      rescue Manual::NotFoundError
        dry_run ? missing_paths[:manuals] << child["base_path"] : raise
      rescue Mongoid::Errors::DocumentNotFound
        dry_run ? missing_paths[:sections] << child["base_path"] : raise
      end
    end

    missing_paths if dry_run
  end

private

  attr_reader :discard_drafts, :user, :csv_path, :dry_run

  def grouped_sections_by_manual
    CSV.read(Rails.root.join(csv_path), headers: true).group_by do |route|
      route["base_path"].split("/")[0..1].join("/")
    end
  end

  def updates_page?(base_path)
    if base_path =~ /^guidance\/.*\/updates$/
      log("Updates page '#{base_path}' will be redirected to Manual's redirect, if provided") unless dry_run
      true
    end
  end

  def withdraw_and_redirect_manual(child)
    WithdrawAndRedirectManual.new(
      user:,
      manual_path: child["base_path"],
      redirect: child["redirect"],
      include_sections: false,
      discard_drafts:,
      dry_run:,
    ).execute

    log("Withdrawn manual '#{child['base_path']}' and redirected to '#{child['redirect']}'") unless dry_run
  end

  def withdraw_and_redirect_section(child, manual_path)
    WithdrawAndRedirectSection.new(
      user:,
      manual_path:,
      section_path: child["base_path"],
      redirect: child["redirect"],
      discard_draft: discard_drafts,
      dry_run:,
    ).execute

    log("Withdrawn section '#{child['base_path']}' and redirected to '#{child['redirect']}'") unless dry_run
  end

  def log(str)
    $stdout.puts(str)
  end
end
