After do
  log_out
end

After do
  Timecop.return
end

Before do
  stub_publishing_api
end
