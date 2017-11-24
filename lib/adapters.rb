module Adapters
  def self.organisations
    @organisations ||= OrganisationsAdapter.new
  end

  def self.publishing
    @publishing ||= PublishingAdapter.new
  end
end
