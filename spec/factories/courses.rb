FactoryBot.define do
  factory :course do
    sequence(:name) { |n| "#{Faker::Educator.course_name} #{n}".truncate(100, omission: "") }
    description { Faker::Lorem.paragraph }

    trait :without_description do
      description { nil }
    end
  end
end
