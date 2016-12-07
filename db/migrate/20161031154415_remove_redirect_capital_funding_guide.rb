require "manual_relocator"
require "cli_manual_deleter"
require "stringio"

class RemoveRedirectCapitalFundingGuide < Mongoid::Migration
  def self.up
    bad_manual_id = "7228d773-a416-4ec1-9549-5fb91b1caaf5"
    manual_slug = "guidance/capital-funding-guide"
    new_manual_slug = "#{manual_slug}-hca"

    CliManualDeleter.new(manual_slug, manual_id: bad_manual_id, stdin: StringIO.new("y")).call

    ManualRelocator.move(new_manual_slug, manual_slug)
  end

  def self.down
  end
end
