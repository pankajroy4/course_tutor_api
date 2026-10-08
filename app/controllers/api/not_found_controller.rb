class Api::NotFoundController < ApplicationController
	def route_not_found
		render json: { errors: ["No route matches #{request.method} #{request.fullpath}"] }, status: :not_found
	end
end

 