class Tutor < ApplicationRecord
  belongs_to :course

  validates :name, presence: true, length: { maximum: 30 }
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  # Note: I removed the email uniqueness check from here becz it was causing N+1 query during validation run. Since tutors are currently created only through nested attributes, I check uniqueness in Course model with custom validation method. It is enforced at DB level too.
end
