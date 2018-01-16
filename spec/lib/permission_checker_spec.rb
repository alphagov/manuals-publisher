require "spec_helper"

describe PermissionChecker do
  let(:generic_writer) { FactoryBot.build(:generic_writer) }
  let(:generic_editor) { FactoryBot.build(:generic_editor) }
  let(:gds_editor)     { FactoryBot.build(:gds_editor) }

  describe "#can_publish?" do
    context "a user who is not an editor" do
      subject(:checker) { PermissionChecker.new(generic_writer) }

      it "prevents publishing" do
        expect(checker.can_publish?).to be false
      end
    end

    context "an editor" do
      subject(:checker) { PermissionChecker.new(generic_editor) }

      it "allows publishing" do
        expect(checker.can_publish?).to be true
      end
    end

    context "a GDS editor" do
      subject(:checker) { PermissionChecker.new(gds_editor) }

      it "allows publishing" do
        expect(checker.can_publish?).to be true
      end
    end
  end

  describe "#can_withdraw?" do
    context "a user who is not an editor" do
      subject(:checker) { PermissionChecker.new(generic_writer) }

      it "prevents withdrawal" do
        expect(checker.can_withdraw?).to be false
      end
    end

    context "an editor" do
      subject(:checker) { PermissionChecker.new(generic_editor) }

      it "allows withdrawal" do
        expect(checker.can_withdraw?).to be true
      end
    end

    context "a GDS editor" do
      subject(:checker) { PermissionChecker.new(gds_editor) }

      it "allows withdrawal" do
        expect(checker.can_withdraw?).to be true
      end
    end
  end

  describe "#is_gds_editor?" do
    it "is true for a GDS editor" do
      checker = PermissionChecker.new(gds_editor)
      expect(checker.is_gds_editor?).to be true
    end

    it "is false for a non-GDS editor" do
      checker = PermissionChecker.new(generic_editor)
      expect(checker.is_gds_editor?).to be false
    end
  end
end
