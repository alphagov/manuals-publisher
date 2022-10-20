require "spec_helper"

RSpec.describe WithdrawAndRedirectToMultiplePaths do
  let(:discard_drafts) { false }
  let(:dry_run) { false }

  let(:withdraw_and_redirect_manual) { double(:withdraw_and_redirect_manual) }
  let(:withdraw_and_redirect_section) { double(:withdraw_and_redirect_section) }

  subject do
    described_class.new(
      csv_path: "spec/support/withdraw_and_redirect_to_multiple_paths.csv",
      discard_drafts:,
      dry_run:,
    )
  end

  before do
    allow(WithdrawAndRedirectManual).to receive(:new) { withdraw_and_redirect_manual }
    allow(withdraw_and_redirect_manual).to receive(:execute)

    allow(WithdrawAndRedirectSection).to receive(:new) { withdraw_and_redirect_section }
    allow(withdraw_and_redirect_section).to receive(:execute)
  end

  it "withdraws and redirects a manual" do
    expect { subject.execute }.to output.to_stdout

    expect(WithdrawAndRedirectManual).to have_received(:new).with(
      user: instance_of(User),
      manual_path: "guidance/published",
      redirect: "/guidance/redirect",
      include_sections: false,
      discard_drafts: false,
      dry_run: false,
    )

    expect(withdraw_and_redirect_manual).to have_received(:execute)
  end

  it "withdraws and redirects section" do
    expect { subject.execute }.to output.to_stdout

    expect(WithdrawAndRedirectSection).to have_received(:new).with(
      user: instance_of(User),
      manual_path: "guidance/manual",
      section_path: "guidance/manual/just-a-section",
      redirect: "/guidance/section-blah",
      discard_draft: false,
      dry_run: false,
    )

    expect(withdraw_and_redirect_section).to have_received(:execute)
  end

  it "skips updates page" do
    expect { subject.execute }.to output(
      /Updates page 'guidance\/published\/updates' will be redirected to Manual's redirect, if provided\n/,
    ).to_stdout
  end

  it "rescues and logs error if a manual isn't published" do
    allow(withdraw_and_redirect_manual).to receive(:execute).and_raise(WithdrawAndRedirectManual::ManualNotPublishedError)

    expect { subject.execute }.to output(
      /\[ERROR\] Manual not redirected due to not being in a published state: guidance\/published/,
    ).to_stdout
  end

  it "rescues and logs error if a section isn't published" do
    allow(withdraw_and_redirect_section).to receive(:execute).and_raise(WithdrawAndRedirectSection::SectionNotPublishedError)

    expect { subject.execute }.to output(
      /\[ERROR\] Section not redirected due to not being in a published state: guidance\/manual\/just-a-section/,
    ).to_stdout
  end

  it "raises error if manual is not found" do
    allow(withdraw_and_redirect_section).to receive(:execute).and_raise(Manual::NotFoundError)
    expect { subject.execute }
      .to output.to_stdout
      .and raise_error(Manual::NotFoundError)
  end

  it "raises error if section is not found" do
    allow(withdraw_and_redirect_section).to receive(:execute)
      .and_raise(Mongoid::Errors::DocumentNotFound.new(SectionEdition, anything))
    expect { subject.execute }
      .to output.to_stdout
      .and raise_error(Mongoid::Errors::DocumentNotFound)
  end

  context "when a dry run is flagged" do
    let(:dry_run) { true }

    it "generates a list of missing paths" do
      allow(withdraw_and_redirect_manual).to receive(:execute).and_raise(Manual::NotFoundError)
      allow(withdraw_and_redirect_section).to receive(:execute).and_raise(
        Mongoid::Errors::DocumentNotFound.new(SectionEdition, anything),
      )

      expect(subject.execute).to eq({ manuals: ["guidance/published"], sections: ["guidance/manual/just-a-section"] })
    end
  end
end
