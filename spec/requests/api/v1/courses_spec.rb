require "rails_helper"

RSpec.describe "Api::V1::Courses", type: :request do
  describe "POST /api/v1/courses" do
    let(:valid_params) do
      {
        course: {
          name: "Ruby on Rails",
          description: "Backend fundamentals with Rails",
          tutors_attributes: [ { name: "Pankaj Kumar", email: "pankaj@gmail.com" }, { name: "Asha Rao", email: "asha@gmail.com" } ]
        }
      }
    end

    context "with valid params" do
      it "creates the course with tutors" do
        expect { post "/api/v1/courses", params: valid_params
        }.to change(Course, :count).by(1).and change(Tutor, :count).by(2)
        expect(response).to have_http_status(:created)
      end

      it "returns the created course with tutors" do
        post "/api/v1/courses", params: valid_params
        course_json = response.parsed_body["course"]

        expect(course_json["id"]).to eq(Course.last.id)
        expect(course_json["name"]).to eq("Ruby on Rails")
        expect(course_json["description"]).to eq("Backend fundamentals with Rails")
        expect(course_json["tutors"].pluck("id")).to match_array(Tutor.pluck(:id))
        expect(course_json["tutors"].pluck("name")).to contain_exactly("Pankaj Kumar", "Asha Rao")
        expect(course_json["tutors"].pluck("email")).to contain_exactly("pankaj@gmail.com", "asha@gmail.com")
      end

      it "allows creating a course without any tutors" do
        params = { course: { name: "Java Full Stack" } }
        post "/api/v1/courses", params: params

        expect(response).to have_http_status(:created)
        expect(response.parsed_body["course"]["tutors"]).to eq([])
      end

      it "accepts maximum 50 tutors" do
        params = {
          course: {
            name: "AI Fundamentals",
            tutors_attributes: Array.new(50) { |i| { name: "Tutor #{i}", email: "tutor#{i}@gmail.com" } }
          }
        }

        expect { post "/api/v1/courses", params: params }.to change(Tutor, :count).by(50)
        expect(response).to have_http_status(:created)
        expect(response.parsed_body["course"]["tutors"].size).to eq(50)
      end
    end

    context "when the course is invalid" do
      it "returns a 422 with validation errors without creating anything" do
        params = { course: { description: "Missing course name" } }

        expect { post "/api/v1/courses", params: params }.not_to change(Course, :count)
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body["errors"]).to include("Name can't be blank")
      end
    end

    context "when a tutor is invalid" do
      it "rolls back the whole creation when a tutor has no email" do
        params = valid_params.dup
        params[:course][:tutors_attributes] << { name: "No Email" }

        expect { post "/api/v1/courses", params: params }.to change(Course, :count).by(0).and change(Tutor, :count).by(0)
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "rolls back the creation when email is not an email" do
        params = valid_params.dup
        params[:course][:tutors_attributes] << { name: "Mohan", email: "not-an-email" }

        expect { post "/api/v1/courses", params: params }.to change(Course, :count).by(0).and change(Tutor, :count).by(0)
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "returns a 422 when two tutors have duplicate email" do
        params = {
          course: {
            name: "Ruby Basic",
            tutors_attributes: [
              { name: "Mohan", email: "duplicate@gmail.com" },
              { name: "Krishna", email: "duplicate@gmail.com" }
            ]
          }
        }

        expect { post "/api/v1/courses", params: params }.to change(Course, :count).by(0).and change(Tutor, :count).by(0)
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body["errors"]).to include("Tutors email must be unique")
      end
    end

    context "when more tutors are submitted than the allowed limit" do
      it "returns a 400" do
        params = {
          course: {
            name: "UPSC crash Course",
            tutors_attributes: Array.new(51) { |i| { name: "Tutor #{i}", email: "tutor#{i}@gmail.com" } }
          }
        }

        expect { post "/api/v1/courses", params: params }.to change(Course, :count).by(0).and change(Tutor, :count).by(0)
        expect(response).to have_http_status(:bad_request)
        expect(response.parsed_body["errors"].first).to include("Maximum 50 records")
      end
    end

    context "when a course name is already taken" do
      it "returns a 422 for duplicate course name" do
        create(:course, name: "Ruby on Rails")

        post "/api/v1/courses", params: valid_params
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body["errors"]).to include("Name has already been taken")
      end
    end

    context "when the request includes unpermitted attributes" do
      it "silently drops an unpermitted course attribute" do
        params = { course: { name: "Python Programming", admin: true } }

        post "/api/v1/courses", params: params

        expect(response).to have_http_status(:created)
        expect(response.parsed_body["course"]).not_to have_key("admin")
      end

      it "silently drops an unpermitted nested tutor attribute" do
        params = {
          course: {
            name: "IIT JEE Course",
            tutors_attributes: [ { name: "Pankaj", email: "pankaj@gmail.com", salary: 999_999 } ]
          }
        }

        post "/api/v1/courses", params: params

        expect(response).to have_http_status(:created)
        expect(response.parsed_body["course"]["tutors"].first).not_to have_key("salary")
      end
    end
  end
end
