require "rails_helper"

RSpec.describe Tutor, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:course).required }
  end

  describe "validations" do
    subject { build(:tutor) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_length_of(:name).is_at_most(30) }
    it { is_expected.to validate_presence_of(:email) }

    it { is_expected.to allow_value("rohit@gmail.com").for(:email) }
    it { is_expected.to allow_value("rohit.kumar+tutor@gmail").for(:email) }
    it { is_expected.not_to allow_value("Invaldi email").for(:email) }
    it { is_expected.not_to allow_value("missing-domain@").for(:email) }

    it "is invalid without a course" do
      tutor = build(:tutor, course: nil)

      expect(tutor).not_to be_valid
      expect(tutor.errors[:course]).to include("must exist")
    end
  end
end
