module PublishingAPIUpdateTypes
  UPDATE_TYPES = %w(minor major republish).freeze

  def check_update_type!(update_type)
    if update_type.present? && !UPDATE_TYPES.include?(update_type)
      raise ArgumentError, "update_type '#{update_type}' not recognised"
    end
  end
end
