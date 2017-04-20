require "spec_helper"

describe PublishingAPIWithdrawer do
  it 'unpublishes the entity' do
    publishing_api = double(:publishing_api, unpublish: nil)
    entity = double(:entity, id: 'content-id')
    withdrawer = PublishingAPIWithdrawer.new(entity: entity)
    allow(Services).to receive(:publishing_api).and_return(publishing_api)

    withdrawer.call

    expect(publishing_api).to have_received(:unpublish).with('content-id', type: 'gone')
  end
end
