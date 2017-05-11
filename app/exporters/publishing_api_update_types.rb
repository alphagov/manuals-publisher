require "gds_api_constants"

module PublishingAPIUpdateTypes
  UPDATE_TYPES = [
    GdsApiConstants::PublishingApiV2::MINOR_UPDATE_TYPE,
    GdsApiConstants::PublishingApiV2::MAJOR_UPDATE_TYPE,
    GdsApiConstants::PublishingApiV2::REPUBLISH_UPDATE_TYPE
  ].freeze

  def check_update_type!(update_type)
    if update_type.present? && !UPDATE_TYPES.include?(update_type)
      raise ArgumentError, "update_type '#{update_type}' not recognised"
    end
  end
end
