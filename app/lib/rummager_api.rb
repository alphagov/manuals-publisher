require "gds_api/rummager"

class RummagerApi
  def self.instance
    @rummager_api ||= GdsApi::Rummager.new(Plek.new.find("search"))
  end
end
