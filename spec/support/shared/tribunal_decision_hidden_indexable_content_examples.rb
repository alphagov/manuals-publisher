require "spec_helper"

RSpec.shared_examples_for "tribunal decision hidden_indexable_content" do

  context "without hidden_indexable_content" do
    it "should have body as its indexable_content" do
      allow(document).to receive(:body).and_return("body text")

      allow(document).to receive(:hidden_indexable_content).and_return(nil)
      expect(formatter.indexable_attributes[:indexable_content]).to eq("body text")
    end
  end

  context "with hidden_indexable_content" do
    it "should have hidden_indexable_content as its indexable_content" do
      allow(document).to receive(:body).and_return("body text")
      allow(document).to receive(:hidden_indexable_content).and_return("hidden indexable content text")

      indexable = formatter.indexable_attributes[:indexable_content]
      expect(indexable).to eq("hidden indexable content text\nbody text")
    end
  end
end
