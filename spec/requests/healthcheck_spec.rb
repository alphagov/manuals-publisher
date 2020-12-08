require "spec_helper"

RSpec.describe "healthcheck path", type: :request do
  it "should return a 200 response" do
    get "/healthcheck"

    expect(response.status).to eq(200)
  end

  it "should return a JSON response with 'status' and 'checks' fields" do
    get "/healthcheck"

    json = JSON.parse(response.body)
    expect(json["status"]).to eq("ok")
    expect(json["checks"]).to include(
      "database_connectivity",
      "redis_connectivity",
    )
  end
end
