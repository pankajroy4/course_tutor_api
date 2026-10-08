require "rails_helper"

RSpec.describe "Api::BaseController" do
  describe "ActionDispatch::Http::Parameters::ParseError" do
    it "returns 400 for invlaid parameter" do
      post "/api/v1/courses", params: "abcd"

      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body["errors"]).to be_present
    end
  end

  describe "ActionController::ParameterMissing" do
    it "returns 400 when the course key is missing" do
      post "/api/v1/courses", params: { not_course: { name: "Ruby on Rails" } }

      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body["errors"].first).to include("param is missing")
    end
  end

  describe "Pagy::VariableError" do
    it "returns 400 with error message for an invalid page" do
      create(:course)

      get "/api/v1/courses", params: { page: -1 }

      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body["errors"]).to eq([ "Invalid page parameter." ])
    end
  end

  describe "StandardError" do
    it "returns generic 500 for unexpected error" do
      get "/api/v1/courses", params: { page: [ "1", "2" ] }

      expect(response).to have_http_status(:internal_server_error)
      expect(response.parsed_body["errors"]).to eq([ "Something went wrong." ])
    end
  end
end
