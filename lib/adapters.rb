module Adapters
  def self.organisations
    @organisations ||= OrganisationsAdapter.new
  end

  def self.search_index
    @search_index ||= SearchIndexAdapter.new
  end
end
