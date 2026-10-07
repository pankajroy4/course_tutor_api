class CreateCourses < ActiveRecord::Migration[8.1]
  def change
    create_table :courses do |t|
      t.string :name
      t.string :description

      t.timestamps
    end

    add_index :courses, "LOWER(name)", unique: true, name: "index_courses_on_lower_name" # case-insensitive uniqueness 
    
  end
end
