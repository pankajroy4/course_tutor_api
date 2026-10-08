FactoryBot.define do
  factory :tutor do
    name { Faker::Name.name.truncate(30, omission: "") }
    sequence(:email) { |n| "tutor#{n}@#{Faker::Internet.domain_name}" }
    course
  end
end
