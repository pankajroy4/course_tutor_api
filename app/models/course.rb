class Course < ApplicationRecord
  has_many :tutors, dependent: :destroy

  validates :name, presence: true, length: { maximum: 100 }, uniqueness: { case_sensitive: false }
  validates :description, length: { maximum: 5_000 }, allow_blank: true

  accepts_nested_attributes_for :tutors  
  # NOTE: I considered extracting this into a Form Object as suggested in "7 Patterns to Refactor Fat ActiveRecord Models". However, given the simplicity of this use case, I chose to keep the implementation straightforward and avoid unnecessary abstraction overhead. 
end
