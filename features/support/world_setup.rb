World(ActiveSupport::Testing::TimeHelpers) if respond_to?(:World)

After do
  log_out
  travel_back
end

Before do
  stub_publishing_api
end
