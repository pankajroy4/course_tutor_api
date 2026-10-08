class CourseSerializer < ActiveModel::Serializer
  attributes :id, :name, :description

  has_many :tutors, serializer: TutorSerializer
end
