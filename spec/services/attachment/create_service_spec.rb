RSpec.describe Attachment::CreateService do
  let(:user) { User.gds_editor }
  let(:manual) { Manual.new(title: "manual-title") }
  let(:section_uuid) { "section-uuid" }
  let(:section) { Section.new(uuid: section_uuid) }
  let(:attachment) { double(:attachment) }
  let(:attributes) { { title: "attachment-title", file: double(:file) } }

  subject do
    described_class.new(
      user:,
      manual_id: manual.id,
      section_uuid:,
      attributes:,
    )
  end

  before do
    allow(manual).to receive(:sections).and_return([section])
    allow(manual).to receive(:save!)
    allow(Manual).to receive(:find).with(manual.id, user).and_return(manual)
    allow(section).to receive(:add_attachment).and_return(attachment)
  end

  it "adds the attachment to the section" do
    expect(section).to receive(:add_attachment).with(attributes)

    subject.call
  end

  it "marks the manual as draft" do
    expect(manual).to receive(:draft)

    subject.call
  end

  it "saves the manual" do
    expect(manual).to receive(:save!).with(user)

    subject.call
  end

  it "returns the manual, section and attachment" do
    expect(subject.call).to eq([manual, section, attachment])
  end
end
