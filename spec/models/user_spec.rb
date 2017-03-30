require 'spec_helper'
require 'gds-sso/lint/user_spec'

describe User, type: :model do
  it_behaves_like "a gds-sso user class"

  describe '#manual_records' do
    let(:permission_checker) { double(:permission_checker) }

    before do
      allow(PermissionChecker).to receive(:new).and_return(permission_checker)
      allow(permission_checker).to receive(:is_gds_editor?).and_return(is_gds_editor)
      allow(ManualRecord).to receive(:all).and_return(:all_manual_records)
      allow(ManualRecord).to receive(:where).with(organisation_slug: subject.organisation_slug).and_return(:manual_records_for_organisation)
    end

    context 'when user is a GDS editor' do
      let(:is_gds_editor) { true }

      it 'returns all manual records' do
        expect(subject.manual_records).to eq(:all_manual_records)
      end
    end

    context 'when user is not a GDS editor' do
      let(:is_gds_editor) { false }

      it "returns only the manual records for the user's organisation" do
        expect(subject.manual_records).to eq(:manual_records_for_organisation)
      end
    end
  end
end
