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

World(PublishingAPIHelpers)
World(OrganisationsAPIHelpers)
World(FormHelpers)
World(ManualHelpers)
World(AttachmentHelpers)
World(FileFixtureHelpers)
World(GdsSsoHelpers)
World(AccessControlHelpers)
