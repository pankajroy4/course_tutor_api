class Api::BaseController < ApplicationController
  include Pagy::Backend
  rescue_from StandardError, with: :render_internal_server_error
  rescue_from ActionController::ParameterMissing, with: :render_bad_request
  rescue_from ActiveRecord::RecordNotUnique, with: :render_record_not_unique
  rescue_from ActionDispatch::Http::Parameters::ParseError, with: :render_bad_request
  rescue_from ActiveRecord::NestedAttributes::TooManyRecords, with: :render_bad_request
  rescue_from Pagy::VariableError, with: :render_bad_request
  # NOTE: I did not add RecordNotFound handling because there is no GET-by-id (show) endpoint that could raise this exception.

  private

  def render_bad_request(exception)
    render json: { error: exception.message }, status: :bad_request 
  end

  def render_record_not_unique(exception)
    index_name = exception.cause&.message.to_s

    field = if index_name.include?("index_courses_on_lower_name")
              "Course's name"
            elsif index_name.include?("index_tutors_on_lower_email")
              "Tutor's email"
            else
              "resource"
            end

    render json: { error: "Record must be unique: #{field}." }, status: :conflict
  end

  def render_internal_server_error(exception)
    Rails.logger.error("[#{exception.class}] #{exception.message}")
    render json: { error: "Something went wrong." }, status: :internal_server_error
  end
end
