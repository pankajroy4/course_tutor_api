class AddNullConstraintToCourseAndTutorName < ActiveRecord::Migration[8.1]
  def change
    change_column_null :courses, :name, false
    change_column_null :tutors, :name, false
  end
end
