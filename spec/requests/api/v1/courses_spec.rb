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

    context "when a database-level unique constraint is violated unexpectedly" do
      it "returns a 409 identifying the violated field for a tutor email collision" do
        allow_any_instance_of(Course).to receive(:save) do
          raise PG::UniqueViolation, 'duplicate key value violates unique constraint "index_tutors_on_lower_email"'
        rescue PG::UniqueViolation
          raise ActiveRecord::RecordNotUnique,
                'duplicate key value violates unique constraint "index_tutors_on_lower_email"'
        end

        post "/api/v1/courses", params: valid_params

        expect(response).to have_http_status(:conflict)
        expect(response.parsed_body["errors"]).to eq([ "Record must be unique: Tutor's email." ])
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

  describe "GET /api/v1/courses" do
    it "returns an empty list and meta when there are no courses" do
      get "/api/v1/courses"
      body = response.parsed_body

      expect(response).to have_http_status(:ok)
      expect(body["courses"]).to eq([])
      expect(body["meta"]).to eq("page" => 1, "pages" => 1, "count" => 0, "limit" => 20)
    end

    it "returns all course along with its tutors" do
      course = create(:course, name: "Ruby on Rails")
      create(:tutor, course: course, name: "Pankaj Kumar")
      create(:course, name: "React Basics")

      get "/api/v1/courses"
      courses = response.parsed_body["courses"]
      expect(response).to have_http_status(:ok)
      expect(courses.size).to eq(2)

      resp = courses.find { |course| course["name"] == "Ruby on Rails" }
      expect(resp["id"]).to eq(course.id)
      expect(resp["tutors"].pluck("name")).to contain_exactly("Pankaj Kumar")
    end

    it "returns a course with an empty tutors array when there is no tutor" do
      create(:course, name: "UPSC Mains")
      get "/api/v1/courses"

      expect(response.parsed_body["courses"].first["tutors"]).to eq([])
    end

    it "orders courses with the most recently created first" do
      course1 = create(:course, name: "UPSC mains")
      course2 = create(:course, name: "UPSC prelims")

      get "/api/v1/courses"

      names = response.parsed_body["courses"].pluck("name")
      expect(names.index(course2.name)).to be < names.index(course1.name)
    end

    it "paginates defaulting to 20 courses per page" do
      create_list(:course, 25)
      get "/api/v1/courses"

      body = response.parsed_body
      expect(body["courses"].size).to eq(20)
      expect(body["meta"]).to eq("page" => 1, "pages" => 2, "count" => 25, "limit" => 20)
    end

    it "returns the second page when asked" do
      create_list(:course, 25)
      get "/api/v1/courses", params: { page: 2 }

      body = response.parsed_body
      expect(body["courses"].size).to eq(5)
      expect(body["meta"]["page"]).to eq(2)
    end

    it "lets the client ask for a smaller page size" do
      create_list(:course, 10)

      get "/api/v1/courses", params: { per_page: 5 }
      body = response.parsed_body
      expect(body["courses"].size).to eq(5)
      expect(body["meta"]["limit"]).to eq(5)
    end

    it "clamps an oversized per_page" do
      create_list(:course, 10)

      get "/api/v1/courses", params: { per_page: 99_999 }
      expect(response.parsed_body["meta"]["limit"]).to eq(100)
    end

    it "falls back to the default page size for a zero, negative, or non-numeric per_page" do
      create_list(:course, 25)

      [ 0, -5, "abc" ].each do |invalid_value|
        get "/api/v1/courses", params: { per_page: invalid_value }

        expect(response.parsed_body["meta"]["limit"]).to eq(20)
      end
    end
  end
end
