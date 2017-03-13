require "spec_helper"

describe PermissionChecker do
  let(:cma_writer)   { FactoryGirl.build(:cma_writer) }
  let(:dclg_editor)  { FactoryGirl.build(:dclg_editor) }
  let(:gds_editor)   { FactoryGirl.build(:gds_editor) }

  describe "#can_edit?" do
    context "a user who is not an editor" do
      subject(:checker) { PermissionChecker.new(cma_writer) }

      context "editing a manual" do
        it "allows editing" do
          expect(checker.can_edit?(PermissionChecker::MANUAL_FORMAT)).to be true
        end
      end
    end

    context "a GDS editor" do
      subject(:checker) { PermissionChecker.new(gds_editor) }

      it "allows editing of any format" do
        expect(checker.can_edit?("tea_and_cake")).to be true
      end
    end
  end

  describe "#can_publish?" do
    context "a user who is not an editor" do
      subject(:checker) { PermissionChecker.new(cma_writer) }

      it "prevents publishing" do
        expect(checker.can_publish?).to be false
      end
    end

    context "an editor" do
      subject(:checker) { PermissionChecker.new(dclg_editor) }

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
      subject(:checker) { PermissionChecker.new(cma_writer) }

      it "prevents withdrawal" do
        expect(checker.can_withdraw?).to be false
      end
    end

    context "an editor" do
      subject(:checker) { PermissionChecker.new(dclg_editor) }

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
      checker = PermissionChecker.new(dclg_editor)
      expect(checker.is_gds_editor?).to be false
    end
  end
end
