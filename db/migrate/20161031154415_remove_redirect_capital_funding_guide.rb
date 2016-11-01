require "manual_relocator"

class RemoveRedirectCapitalFundingGuide < Mongoid::Migration
  def self.up
    manual_slug = "guidance/capital-funding-guide"
    new_manual_slug = "#{manual_slug}-hca"

    ManualRelocator.move(new_manual_slug, manual_slug)
  end

  def self.down
  end
end
