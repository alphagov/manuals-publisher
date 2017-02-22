require "webmock/cucumber"
WebMock.disable_net_connect!

Before("@javascript") do
  WebMock.disable_net_connect!(allow_localhost: true)
end

After("@javascript") do
  WebMock.disable_net_connect!
end
