class Tutor < ApplicationRecord
  belongs_to :course

  validates :name, presence: true, length: { maximum: 30 } 
  validates :email, presence: true, uniqueness: { case_sensitive: false }, format: { with: URI::MailTo::EMAIL_REGEXP } 
end
