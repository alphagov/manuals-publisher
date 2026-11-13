require "rake"

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

  it "shows the old and new slugs" do
    expect { task.invoke("guidance/old-manual", "guidance/new-manual") }
      .to output(%r{guidance/old-manual.*guidance/new-manual}m).to_stdout
  end

  it "reslugs the manual" do
    task.invoke("guidance/old-manual", "guidance/new-manual")

    expect(ManualReslugger).to have_received(:new).with("guidance/old-manual", "guidance/new-manual")
    expect(reslugger).to have_received(:call)
  end
end
