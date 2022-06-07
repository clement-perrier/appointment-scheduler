

class AuthController < ApplicationController
	
    require 'http'

    $app_url = 'http://localhost:3000'
    $github_login_url = 'https://github.com/login/oauth/authorize?'
    $github_client_id = '6934daa32c8ee5a0c4ed'
    $github_client_secret = '58450da3e1788457fbdd9f95f74dbde9116be9aa'
    $github_redirect_url = $app_url + '/auth/github/cb'
    $github_access_token_url = 'https://github.com/login/oauth/access_token'
    $github_user_url = 'https://api.github.com/user'

	def index
		session[:github_auth_state] = ""
	end
	
	def login
		session[:github_auth_state] = SecureRandom.alphanumeric(10)

		github = $github_login_url +
			"client_id=" + $github_client_id +
			"&redirect_uri=" + $github_redirect_url +
			"&scope=user&state=" + session[:github_auth_state]

			redirect_to github
	end

	def cb
		state = params[:state]

		if state === session[:github_auth_state]

			response = request_access_token($github_access_token_url, {
				:client_id => $github_client_id,
				:client_secret => $github_client_secret,
				:code => params[:code],
				:redirect_uri => $github_redirect_url,
				:state => session[:github_auth_state]
			})

			if response.code === 200
				
				access_token = response.parse['access_token']

				github_user_response = request_user_info($github_user_url, access_token)

				if github_user_response.code === 200
					
					github_user = github_user_response.parse

					user = User.find_by(uid: github_user['id'])
					
					if (!user)
						user = User.create(
							username: github_user['login'],
							email: github_user['email'],
							uid: github_user['id'],
							provider: 'github',
							token: access_token
						)
					else
						user.token = access_token
						user.save
					end

					# session[:current_user_id] = user.id
					log_in(user)
			
					session[:github_auth_state] = ""

					flash[:notice] = "You have successfully logged in."
				end
			else
				flash[:danger] = "Failed attempt!"
			end
		else
			# If the states don't match, then a third party created the request, and you should abort the process.
			flash[:danger] = "Failed attempt!"
		end

		redirect_to root_url
	end

	def logout
		log_out
		flash[:notice] = "You have successfully logged out."
    redirect_to root_url
	end

	private def request_access_token(url, params)
		HTTP.headers(:accept => 'application/json')
				.post(url, :json => params)
	end

	private def request_user_info(url, token)
		HTTP.auth('token ' + token)
			.get(url)
	end

end
