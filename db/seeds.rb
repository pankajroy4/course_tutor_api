# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end


courses = [
  { name: "Ruby on Rails Development", description: "Build production grade APIs and web apps with Ruby on Rails." },

  { name: "DevOps Engineering", description: "CI/CD pipelines, containerization, and infrastructure automation." },

  { name: "Machine Learning Fundamentals", description: "Supervised and unsupervised learning algorithms from scratch." },

  { name: "UPSC Prelims General Studies", description: "Comprehensive coverage of GS Paper I for UPSC Prelims." },
  { name: "IIT JEE Mathematics Advanced", description: "Calculus, algebra, and coordinate geometry for JEE Advanced." }

]

tutors_by_course = {
  "Ruby on Rails Development" => { name: "Pankaj Kumar", email: "pankaj@example.com" },
  "DevOps Engineering" => { name: "Priya Gupta", email: "priya@example.com" },
  "Machine Learning Fundamentals" => { name: "Sneha Singh", email: "sneha@example.com" },
  "UPSC Prelims General Studies" => { name: "Ankit Verma", email: "ankit@example.com" },
  "IIT JEE Mathematics Advanced" => { name: "Vikram Rathor", email: "vikram@example.com" }
}

courses.each do |course_attrs|
  course = Course.find_or_create_by!(name: course_attrs[:name]) do |c|
    c.description = course_attrs[:description]
  end

  tutor_attrs = tutors_by_course[course_attrs[:name]]
  next unless tutor_attrs

  course.tutors.find_or_create_by!(email: tutor_attrs[:email]) do |t|
    t.name = tutor_attrs[:name]
  end
end

puts "Seeded successful"
