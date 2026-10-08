require "rails_helper"

RSpec.describe "Unmatched routes", type: :request do
  it "returns a JSON 404 for unmatched route" do
    get "/api/v1/unmatched"

    expect(response).to have_http_status(:not_found)
    expect(response.parsed_body["errors"].first).to include("No route matches")
  end

  it "returns a JSON 404 for unknown route" do
    get "/unknown/route"

    expect(response).to have_http_status(:not_found)
  end

  it "returns a JSON 404 for a route with an unsupported HTTP method" do
    delete "/api/v1/courses/1"

    expect(response).to have_http_status(:not_found)
    expect(response.parsed_body["errors"].first).to include("No route matches")
  end
end
