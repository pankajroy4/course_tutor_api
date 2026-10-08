class Api::V1::CoursesController < Api::BaseController
  def index
    pagy, courses = pagy(Course.includes(:tutors).order(created_at: :desc), limit: per_page)

    render json: courses, each_serializer: CourseSerializer,
            meta: { page: pagy.page, pages: pagy.pages, count: pagy.count, limit: pagy.limit }
  end


  def create
    course = Course.new(course_params)

    if course.save
      render json: course, serializer: CourseSerializer, status: :created
    else
      render json: { errors: course.errors.full_messages }, status: :unprocessable_content
    end
  end

  private

  def per_page
    value = params[:per_page].to_i
    value.positive? ? value.clamp(1, 100) : Pagy::DEFAULT[:limit]
  end
  
  def course_params
    params.require(:course).permit(
      :name,
      :description,
      tutors_attributes: %i[name email]
    )
  end
end
