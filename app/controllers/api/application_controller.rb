module Api
  class ApplicationController < ActionController::Base
    before_action :authenticate!

  private

    def authenticate!
      token = Token.where(value: authorization_token).first
      unless token || super_admin
        render json: { errors: 'Unauthorized' }, status: :unauthorized
      end
    end

    def authorization_token
      request.headers['AUTHORIZATION'] || params[:token]
    end

    def super_admin
      current_user.present? && current_user.super_admin?
    end

    def current_user
      current_user = Login.current_user(session)
    end

  end
end
