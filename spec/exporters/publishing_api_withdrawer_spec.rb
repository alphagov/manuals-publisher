require "spec_helper"

describe PublishingAPIWithdrawer do
  it 'unpublishes the entity' do
    publishing_api = double(:publishing_api, unpublish: nil)
    entity = double(:entity, id: 'content-id')
    withdrawer = PublishingAPIWithdrawer.new(publishing_api: publishing_api, entity: entity)

    withdrawer.call

    expect(publishing_api).to have_received(:unpublish).with('content-id', type: 'gone')
  end
end
