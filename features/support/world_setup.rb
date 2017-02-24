After do
  log_out
end

After do
  Timecop.return
end

Before do
  # WARNING: These must be stubbed before the first request takes place
  stub_rummager
  stub_publishing_api
end

Test::Unit::AutoRunner.need_auto_run = false if defined?(Test::Unit::AutoRunner)

World(RummagerHelpers)
World(PublishingAPIHelpers)
World(OrganisationsAPIHelpers)
World(FormHelpers)
World(DocumentHelpers)
World(ManualHelpers)
World(AttachmentHelpers)
World(FileFixtureHelpers)
World(GdsSsoHelpers)
World(AccessControlHelpers)
