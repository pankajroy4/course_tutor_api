class AddNotNullConstraintToTutorEmail < ActiveRecord::Migration[8.1]
  def change
    change_column_null :tutors, :email, false
  end
end
