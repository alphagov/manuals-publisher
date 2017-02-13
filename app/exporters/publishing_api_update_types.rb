module PublishingAPIUpdateTypes
  UPDATE_TYPES = %w(minor major republish).freeze
  def check_update_type!(update_type, allow_nil: true)
    return if update_type.nil? && allow_nil
    raise ArgumentError, "update_type '#{update_type}' not recognised" unless UPDATE_TYPES.include?(update_type)
  end
end
