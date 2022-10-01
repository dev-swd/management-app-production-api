class ApplicationController < ActionController::API
	include AbstractController::Helpers
	include DeviseTokenAuth::Concerns::SetUserByToken

	skip_before_action :verify_authenticity_token, raise: false
	helper_method :current_user, :user_signed_in?
end
