class Course < ApplicationRecord
  has_many :tutors, dependent: :destroy

  validates :name, presence: true, length: { maximum: 100 }, uniqueness: { case_sensitive: false }
  validates :description, length: { maximum: 5_000 }, allow_blank: true
  validate :tutors_have_unique_emails

  accepts_nested_attributes_for :tutors, limit: 50
  # NOTE:
  # 1. I considered extracting this into a Form Object as suggested in "7 Patterns to Refactor Fat ActiveRecord Models". For this simple use case, I keep the implementation straightforward and avoid abstraction.

  # 2. The nested attributes are limited to 50 tutors per request to prevent large payloads. For the large scale, I would move tutor creation to a background job and process the records in batches using bulk inserts, with input validation.

  private

  def tutors_have_unique_emails
    new_tutors = tutors.target.select(&:new_record?) # Do not forces association to laod from db
    emails = new_tutors.map(&:email).compact.map(&:downcase)
    return if emails.empty?

    duplicate_within_batch = emails.uniq.size != emails.size
    already_taken = Tutor.where("LOWER(email) IN (?)", emails).exists?

    errors.add(:tutors, "email must be unique") if duplicate_within_batch || already_taken
  end
end
