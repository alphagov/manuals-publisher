After do
  log_out
end

After do
  Timecop.return
end

Before do
  stub_publishing_api
end

Test::Unit::AutoRunner.need_auto_run = false if defined?(Test::Unit::AutoRunner)
