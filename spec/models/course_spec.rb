require "rails_helper"

RSpec.describe Course, type: :model do
  describe "associations" do
    it { is_expected.to have_many(:tutors).dependent(:destroy) } 
    it { is_expected.to accept_nested_attributes_for(:tutors).limit(50).allow_destroy(false) }
  end

  describe "validations" do
    subject { build(:course) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_length_of(:name).is_at_most(100) }
    it { is_expected.to validate_uniqueness_of(:name).case_insensitive }
    it { is_expected.to validate_length_of(:description).is_at_most(5_000) }

    it "is valid without description" do
      course = build(:course, :without_description) 
      expect(course).to be_valid
    end

    it "is valid with empty description" do
      course = build(:course, description: "")
      expect(course).to be_valid
    end

    it "is valid without tutors" do
      course = build(:course)
      expect(course).to be_valid
      expect(course.tutors).to be_empty
    end
  end

  describe "nested attributes" do
    it "accepts tutor attributes" do
      course = Course.new( name: "Number Theory", tutors_attributes: [ { name: "Rohit", email: "rohit@gmail.com" } ])

      expect(course.tutors.size).to eq(1)
      expect(course.tutors.first.name).to eq("Rohit")
    end

    it "allows maximum 50 nested tutors" do
      attributes = Array.new(50) { |i| { name: "Tutor #{i}", email: "tutor#{i}@gmail.com" } }

      course = Course.new(name: "Ruby on rails mastery", tutors_attributes: attributes)
      expect(course.tutors.size).to eq(50)
    end

    it "raises error when more than 50 tutors" do
      attributes = Array.new(51) { |i| { name: "Tutor #{i}", email: "tutor#{i}@gmail.com" } }

      expect {
        Course.new(name: "Java Full Stack", tutors_attributes: attributes)
      }.to raise_error(ActiveRecord::NestedAttributes::TooManyRecords)
    end
  end

  describe "tutor email uniqueness" do
    it "is invalid when duplicate email passed for tutors" do
      course1 = Course.new(
        name: "English Grammar",
        tutors_attributes: [
          { name: "Radha", email: "duplicate@gmail.com" },
          { name: "Priya", email: "duplicate@gmail.com" }
        ]
      )

      course2 = Course.new(
        name: "Hotwire full course",
        tutors_attributes: [ 
          { name: "Rakesh", email: "duplicate2@gmail.com" },
          { name: "Lalit", email: "DUPLICATE2@GMAIL.COM" }
        ]
      )

      expect(course1).not_to be_valid
      expect(course1.errors[:tutors]).to include("email must be unique")

      expect(course2).not_to be_valid
      expect(course2.errors[:tutors]).to include("email must be unique")
    end

    it "is invalid when a tutor's email is already exists" do
      create(:tutor, email: "pankaj@gmail.com")

      course = Course.new(
        name: "UPSC crash course",
        tutors_attributes: [ { name: "Pankaj", email: "pankaj@gmail.com" } ]
      )

      expect(course).not_to be_valid
      expect(course.errors[:tutors]).to include("email must be unique")
    end
  end

  describe "#destroy" do
    it "destroy course along with its tutors" do
      course = create(:course) 
      create_list(:tutor, 3, course: course)

      expect { course.destroy }.to change(Tutor, :count).by(-3)
    end
  end
end

