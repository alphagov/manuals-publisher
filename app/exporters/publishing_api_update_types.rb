module PublishingAPIUpdateTypes
  UPDATE_TYPES = %w(minor major republish).freeze

  def check_update_type!(update_type)
    return if update_type.nil?
    raise ArgumentError, "update_type '#{update_type}' not recognised" unless UPDATE_TYPES.include?(update_type)
  end
end
