require "singleton"
require "gds_api/email_alert_api"

module EmailAlertAPIHelpers

  class FakeEmailAlertAPI
    include Singleton

    def send_alert(publication)
    end
  end

  def stub_delivery_api
    allow(GdsApi::EmailAlertApi).to receive(:new)
      .and_return(fake_email_alert_api)

    allow(fake_email_alert_api).to receive(:send_alert).and_call_original
  end

  def reset_delivery_api_stubs_and_messages
    RSpec::Mocks.space.proxy_for(fake_email_alert_api).reset
    stub_delivery_api
  end

  def fake_email_alert_api
    FakeEmailAlertAPI.instance
  end
end
