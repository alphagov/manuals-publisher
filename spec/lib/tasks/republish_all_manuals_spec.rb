require "rake"
require "thor"

describe "republish_all_manuals" do
  before :all do
    Rake::Task.define_task(:environment)
    Rake.application.rake_require("lib/tasks/republish_all_manuals", [Rails.root.to_s])
  end

  before :each do
    task.reenable
    allow($stdout).to receive(:puts)
    allow_any_instance_of(Thor::Shell::Basic).to receive(:yes?).and_return(true)
  end

  let(:task) { Rake::Task["republish_all_manuals"] }
  let(:logger) { instance_double(Logger, info: nil) }
  let(:manual_record) { FactoryBot.create(:manual_record, slug: "test-slug") }
  let(:section_edition) { FactoryBot.create(:section_edition, section_uuid: "1234", slug: "test-slug", state: "published") }
  let!(:manual_edition) do
    manual_record.editions.create!(
      state: "published",
      version_number: 1,
      section_uuids: [section_edition.section_uuid],
    )
  end
  let(:republisher) { instance_double(ManualsRepublisher) }

  before do
    allow(Logger).to receive(:new).and_return(logger)
    allow(logger).to receive(:formatter=)
    allow(ManualRecord).to receive(:all).and_return([manual_record])
    allow(ManualsRepublisher).to receive(:new).and_return(republisher)
    allow(republisher).to receive(:execute)
  end

  it "republishes all manuals for the user" do
    task.invoke

    expect(ManualRecord).to have_received(:all)
    expect(republisher).to have_received(:execute)
  end

  context "when the user aborts" do
    before do
      allow_any_instance_of(Thor::Shell::Basic).to receive(:yes?).and_return(false)
    end

    it "does not republish any manuals" do
      task.invoke

      expect(republisher).not_to have_received(:execute)
    end
  end
end
