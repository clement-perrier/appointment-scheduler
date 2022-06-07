class ApiController < ActionController::API
  def index
    render json: { message: "Welcome to the home page" }, status: 200
  end
end
