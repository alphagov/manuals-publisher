require "rake"
require "thor"

describe "reslug_manual" do
  before :all do
    Rake::Task.define_task(:environment)
    Rake.application.rake_require("lib/tasks/reslug_manual", [Rails.root.to_s])
  end

  let(:task) { Rake::Task["reslug_manual"] }
  let(:reslugger) { instance_double(ManualReslugger, call: nil) }

  before do
    task.reenable
    allow($stdout).to receive(:puts)
    allow(ManualReslugger).to receive(:new).and_return(reslugger)
  end

  it "shows the old and new slugs before asking for confirmation" do
    allow_any_instance_of(Thor::Shell::Basic).to receive(:yes?).and_return(true)

    expect { task.invoke("guidance/old-manual", "guidance/new-manual") }
      .to output(%r{guidance/old-manual.*guidance/new-manual}m).to_stdout
  end

  context "when the user confirms" do
    before { allow_any_instance_of(Thor::Shell::Basic).to receive(:yes?).and_return(true) }

    it "reslugs the manual" do
      task.invoke("guidance/old-manual", "guidance/new-manual")

      expect(ManualReslugger).to have_received(:new).with("guidance/old-manual", "guidance/new-manual")
      expect(reslugger).to have_received(:call)
    end
  end

  context "when the user aborts" do
    before { allow_any_instance_of(Thor::Shell::Basic).to receive(:yes?).and_return(false) }

    it "does not reslug the manual" do
      task.invoke("guidance/old-manual", "guidance/new-manual")

      expect(reslugger).not_to have_received(:call)
    end
  end
end
