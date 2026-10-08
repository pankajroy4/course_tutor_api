class MakeTutorEmailsCaseInsensitive < ActiveRecord::Migration[8.1]
  def change
    remove_index :tutors, :email

    add_index :tutors, "LOWER(email)", unique: true, name: "index_tutors_on_lower_email"
  end
end
