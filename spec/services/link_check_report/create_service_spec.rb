require "spec_helper"

RSpec.describe LinkCheckReport::CreateService do
  let(:user) { FactoryGirl.create(:user) }

  let(:link_check_report) { double(:link_check_report, valid?: nil, save!: nil) }

  let(:link_checker_api_response) do
    {
      batch_id: 1,
      completed_at: nil,
      status: "in_progress",
      links: [
        {
          uri: "http://www.example.com",
          status: "error",
          checked: Time.parse("2017-12-01"),
          warnings: ["example check warnings"],
          errors: ["example check errors"],
          problem_summary: "example problem",
          suggested_fix: "example fix"
        }
      ]
    }
  end

  before do
    allow(Services.link_checker_api).to receive(:create_batch).and_return(link_checker_api_response)
    allow(LinkCheckReport).to receive(:new).and_return(link_check_report)
  end

  context "when checking links for manual" do
    let(:manual) { double(:manual, id: 1, body: "[link](http://www.example.com)") }

    subject do
      described_class.new(
        user: user,
        manual_id: manual.id
      )
    end

    before do
      allow(Manual).to receive(:find).with(manual.id, user).and_return(manual)
    end

    context "when the link checker api is called" do
      it "sets link check api attributes on report" do
        expect(LinkCheckReport).to receive(:new).with(
          hash_including(
            batch_id: 1,
            completed_at: nil,
            status: "in_progress",
            manual_id: manual.id
          )
        )
        subject.call
      end

      it "sets link array on report" do
        expect(LinkCheckReport).to receive(:new).with(
          hash_including(
            links: array_including(
              hash_including(
                uri: "http://www.example.com",
                status: "error",
                checked: Time.parse("2017-12-01"),
                check_warnings: ["example check warnings"],
                check_errors: ["example check errors"],
                problem_summary: "example problem",
                suggested_fix: "example fix"
              )
            )
          )
        )
        subject.call
      end
    end

    context "when the report is valid" do
      it "saves the report" do
        expect(link_check_report).to receive(:save!)
        subject.call
      end
    end

    context "when there are no errors" do
      it "saves errors as an empty array" do
        link_checker_api_response[:links].first.delete(:errors)
        expect(LinkCheckReport).to receive(:new).with(
          hash_including(
            links: array_including(
              hash_including(check_errors: [])
            )
          )
        )
        subject.call
      end
    end

    context "when there are no warnings" do
      it "saves warnings as an empty array" do
        link_checker_api_response[:links].first.delete(:warnings)
        expect(LinkCheckReport).to receive(:new).with(
          hash_including(
            links: array_including(
              hash_including(check_warnings: [])
            )
          )
        )
        subject.call
      end
    end

    context "when the report is invalid" do
      it "throws an exception" do
        fake_validation_error = Mongoid::Errors::Validations.new(double(errors: double(full_messages: [])))
        expect(link_check_report).to receive(:save!).and_raise(fake_validation_error)
        expect { subject.call }.to raise_error(LinkCheckReport::CreateService::InvalidReport)
      end
    end
  end
end
