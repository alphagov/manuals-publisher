module Adapters
  def self.organisations
    OrganisationsAdapter.new
  end

  def self.search_index
    SearchIndexAdapter.new
  end
end
