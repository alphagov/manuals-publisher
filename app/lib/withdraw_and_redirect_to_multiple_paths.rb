require "csv"

class WithdrawAndRedirectToMultiplePaths
  def initialize(csv_path:, discard_drafts:)
    @csv_path = csv_path
    @discard_drafts = discard_drafts
    @user = User.gds_editor
  end

  def execute
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
      end
    end
  end

private

  attr_reader :discard_drafts, :user, :csv_path

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
      user: user,
      manual_path: child["base_path"],
      redirect: child["redirect"],
      include_sections: false,
      discard_drafts: discard_drafts,
    ).execute

    log("Withdrawn manual '#{child['base_path']}' and redirected to '#{child['redirect']}'") unless dry_run
  end

  def withdraw_and_redirect_section(child, manual_path)
    WithdrawAndRedirectSection.new(
      user: user,
      manual_path: manual_path,
      section_path: child["base_path"],
      redirect: child["redirect"],
      discard_draft: discard_drafts,
    ).execute

    log("Withdrawn section '#{child['base_path']}' and redirected to '#{child['redirect']}'") unless dry_run
  end

  def log(str)
    $stdout.puts(str)
  end
end
