require "spec_helper"

describe ApplicationHelper, type: :helper do
  describe "#allow_publish?" do
    let(:manual) { instance_double(Manual) }

    before do
      @slug_unique = true
      allow(manual).to receive(:draft?).and_return(true)
      allow(manual).to receive_message_chain("sections.any?") { true }
    end

    context "when the current user can publish" do
      def current_user_can_publish? = true

      it "returns true when the manual may be published" do
        allowed = allow_publish?(manual, @slug_unique)

        expect(allowed).to be true
      end

      it "returns false when the manual is not in draft" do
        allow(manual).to receive(:draft?).and_return(false)

        allowed = allow_publish?(manual, @slug_unique)

        expect(allowed).to be false
      end

      it "returns false when the manual does not contain any sections" do
        allow(manual).to receive_message_chain("sections.any?") { false }

        allowed = allow_publish?(manual, @slug_unique)

        expect(allowed).to be false
      end

      it "returns false when the manual's slug is not unique" do
        @slug_unique = false

        allowed = allow_publish?(manual, @slug_unique)

        expect(allowed).to be false
      end
    end

    context "when the current user cannot publish" do
      def current_user_can_publish? = false

      it "returns false" do
        allowed = allow_publish?(manual, @slug_unique)

        expect(allowed).to be false
      end
    end
  end

  describe "#last_updated_text" do
    let(:section) { instance_double(Section, updated_at: Time.zone.now) }

    context "when section is not in draft state" do
      before do
        allow(section).to receive(:draft?).and_return(false)
      end

      it "returns text without author" do
        text = last_updated_text(section)

        expect(text).to eq("Updated less than a minute ago")
      end
    end

    context "when section is in draft state" do
      before do
        allow(section).to receive(:draft?).and_return(true)
      end

      it "returns text including author, when the author is known" do
        allow(section).to receive(:last_updated_by).and_return("Test User")

        text = last_updated_text(section)

        expect(text).to eq("Updated less than a minute ago by Test User")
      end

      it "returns text without author, when the author is not known" do
        allow(section).to receive(:last_updated_by).and_return(nil)

        text = last_updated_text(section)

        expect(text).to eq("Updated less than a minute ago")
      end
    end
  end
end
