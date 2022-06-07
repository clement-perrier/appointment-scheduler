class HomeController < ApplicationController
  def index
    render template: "home/index.erb", locals: { message: "Welcome to the home page" }
  end
end
