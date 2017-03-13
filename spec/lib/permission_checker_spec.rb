require "spec_helper"

describe PermissionChecker do
  let(:generic_writer) { FactoryGirl.build(:generic_writer) }
  let(:dclg_editor)    { FactoryGirl.build(:dclg_editor) }
  let(:gds_editor)     { FactoryGirl.build(:gds_editor) }

  describe "#can_edit?" do
    context "a user who is not an editor" do
      subject(:checker) { PermissionChecker.new(generic_writer) }

      context "editing a manual" do
        it "allows editing" do
          expect(checker.can_edit?("manual")).to be true
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
      subject(:checker) { PermissionChecker.new(generic_writer) }

      it "prevents publishing" do
        expect(checker.can_publish?("manual")).to be false
      end
    end

    context "an editor" do
      subject(:checker) { PermissionChecker.new(dclg_editor) }

      context "publishing a manual" do
        it "allows publishing" do
          expect(checker.can_publish?("manual")).to be true
        end
      end
    end

    context "a GDS editor" do
      subject(:checker) { PermissionChecker.new(gds_editor) }

      it "allows publishing of any format" do
        expect(checker.can_publish?("tea_and_biscuits")).to be true
      end
    end
  end

  describe "#can_withdraw?" do
    context "a user who is not an editor" do
      subject(:checker) { PermissionChecker.new(generic_writer) }

      it "prevents withdrawal" do
        expect(checker.can_withdraw?("manual")).to be false
      end
    end

    context "an editor" do
      subject(:checker) { PermissionChecker.new(dclg_editor) }

      context "withdrawing a manual" do
        it "allows withdrawing" do
          expect(checker.can_withdraw?("manual")).to be true
        end
      end
    end

    context "a GDS editor" do
      subject(:checker) { PermissionChecker.new(gds_editor) }

      it "allows withdrawal of any format" do
        expect(checker.can_withdraw?("tea_and_biscuits")).to be true
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
