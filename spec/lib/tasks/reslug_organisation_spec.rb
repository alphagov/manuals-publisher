require "rake"
require "thor"

describe "reslug_organisation" do
  before :all do
    Rake::Task.define_task(:environment) # depended on by `reslug_organisation`
    Rake.application.rake_require("lib/tasks/reslug_organisation", [Rails.root.to_s])
  end
  before :each do
    task.reenable # without this, calling `invoke` does nothing after first test
    allow($stdout).to receive(:puts) # supress Rake task output
    allow_any_instance_of(Thor::Shell::Basic).to receive(:yes?).and_return(true)
  end
  let(:task) { Rake::Task["reslug_organisation"] }

  describe "validation" do
    let(:error_message) do
      "Invalid parameters provided to `reslug_organisation` Usage: reslug_organisation[old-slug,new-slug]."
    end

    it "raises exception if no args provided" do
      expect { task.invoke }.to raise_error(RuntimeError, error_message)
    end

    it "raises exception if only one arg provided" do
      expect { task.invoke("foo") }.to raise_error(RuntimeError, error_message)
    end
  end

  it "finds all manual records with the given org slug and replaces its slug" do
    manual_records_to_update = [
      FactoryBot.create(:manual_record, organisation_slug: "foo"),
      FactoryBot.create(:manual_record, organisation_slug: "foo"),
    ]

    task.invoke("foo", "bar")

    expect(manual_records_to_update.first.reload[:organisation_slug]).to eq("bar")
    expect(manual_records_to_update.last.reload[:organisation_slug]).to eq("bar")
  end

  it "outputs useful information about which manual records are having their orgs re-slugged" do
    FactoryBot.create(:manual_record, organisation_slug: "foo", manual_id: "abc123", slug: "/guidance/test")
    FactoryBot.create(:manual_record, organisation_slug: "foo", manual_id: "def456", slug: "/guidance/another")

    expected_output = <<~OUTPUT
      Updating the `organisation_slug` of 2 manual records from 'foo' to 'bar'
      - Updating ManualRecord abc123 (/guidance/test)
      - Updating ManualRecord def456 (/guidance/another)
      Done.
    OUTPUT

    expect { task.invoke("foo", "bar") }.to output(expected_output).to_stdout
  end

  it "ignores manual records that have a different org slug" do
    manual_record_to_ignore = FactoryBot.create(:manual_record, organisation_slug: "leave-me-alone")

    task.invoke("foo", "bar")

    expect(manual_record_to_ignore.reload[:organisation_slug]).to eq("leave-me-alone")
  end

  it "does not update any manual records if the user aborts the confirmation prompt" do
    FactoryBot.create(:manual_record, organisation_slug: "foo")
    FactoryBot.create(:manual_record, organisation_slug: "foo")

    allow_any_instance_of(Thor::Shell::Basic).to receive(:yes?).and_return(false)

    expected_output = <<~OUTPUT
      Updating the `organisation_slug` of 2 manual records from 'foo' to 'bar'
      Aborted
    OUTPUT

    expect { task.invoke("foo", "bar") }.to output(expected_output).to_stdout

    # Ensure no records were updated
    expect(ManualRecord.where(organisation_slug: "foo").count).to eq(2)
    expect(ManualRecord.where(organisation_slug: "bar").count).to eq(0)
  end
end
