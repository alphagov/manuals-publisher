RSpec.describe Attachment::UpdateService do
  let(:user) { User.gds_editor }
  let(:manual) { Manual.new(title: "manual-title") }
  let(:section_uuid) { "section-uuid" }
  let(:section) { Section.new(uuid: section_uuid) }
  let(:attachment_id) { "attachment-id" }
  let(:attachment) { double(:attachment, update!: true) }
  let(:file) { double(:file, original_filename: "replacement.pdf") }
  let(:attributes) { { title: "attachment-title", file: } }

  subject do
    described_class.new(
      user:,
      attachment_id:,
      manual_id: manual.id,
      section_uuid:,
      attributes:,
    )
  end

  before do
    allow(manual).to receive(:sections).and_return([section])
    allow(manual).to receive(:save!)
    allow(Manual).to receive(:find).with(manual.id, user).and_return(manual)
    allow(section).to receive(:update_attachment).and_return(attachment)
  end

  it "updates the attachment with the uploaded filename" do
    expect(section).to receive(:update_attachment)
      .with(attachment_id, attributes.merge(filename: "replacement.pdf"))

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
