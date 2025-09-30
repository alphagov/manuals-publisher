require "rake"
require "thor"

describe "republish_manuals" do
  before :all do
    Rake::Task.define_task(:environment)
    Rake.application.rake_require("lib/tasks/republish_manuals", [Rails.root.to_s])
  end

  before :each do
    task.reenable
    allow($stdout).to receive(:puts)
    allow_any_instance_of(Thor::Shell::Basic).to receive(:yes?).and_return(true)
  end

  let(:task) { Rake::Task["republish_manuals"] }
  let(:logger) { instance_double(Logger, info: nil) }
  let(:user) { instance_double(User, email: "test@test.com") }
  let(:manual) { instance_double(Manual, slug: "test-slug") }
  let(:republisher) { instance_double(ManualsRepublisher) }

  before do
    allow(Logger).to receive(:new).and_return(logger)
    allow(logger).to receive(:formatter=)
    allow(User).to receive(:find_by).and_return(user)
    allow(Manual).to receive(:find_by_slug!).and_return(manual)
    allow(Manual).to receive(:all).and_return([manual])
    allow(ManualsRepublisher).to receive(:new).and_return(republisher)
    allow(republisher).to receive(:execute)
  end

  context "when a slug is provided" do
    it "republishes the specified manual" do
      task.invoke("test@test.com", "test-slug")

      expect(User).to have_received(:find_by).with(email: "test@test.com")
      expect(Manual).to have_received(:find_by_slug!).with("test-slug", user)
      expect(republisher).to have_received(:execute).with([manual])
    end
  end

  context "when no slug is provided" do
    it "republishes all manuals for the user" do
      task.invoke("test@test.com")

      expect(User).to have_received(:find_by).with(email: "test@test.com")
      expect(Manual).to have_received(:all).with(user)
      expect(republisher).to have_received(:execute).with([manual])
    end
  end

  context "when the user aborts" do
    before do
      allow_any_instance_of(Thor::Shell::Basic).to receive(:yes?).and_return(false)
    end

    it "does not republish any manuals" do
      task.invoke("test@test.com", "test-slug")

      expect(republisher).not_to have_received(:execute)
    end
  end
end
