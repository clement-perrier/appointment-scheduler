Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html

  root 'auth#index'
  get '/auth/github', to: 'auth#login'
  get '/auth/github/cb', to: 'auth#cb'
  delete 'logout', to: 'auth#logout', as: 'logout'

  #get "/", to: "home#index"
  get "/home", to: "home#index"

  post "/api/home", to: "api#index"
  get '/appointments', to: "appointments#get_appointments", as: 'appointments'
  post '/appointments', to: "appointments#create_appointment", as: 'create_appointment'
  delete '/appointments', to: "appointments#cancel_appointment", as: 'cancel_appointment'
  get '/appointments/create'
  get '/appointments/cancel'

end
