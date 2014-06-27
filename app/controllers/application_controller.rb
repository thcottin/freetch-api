class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :null_session

  include NotificationHelper
  include ApplicationHelper

  before_action :user_agent

  def user_agent
    @ua_string = request.user_agent
  end

  def current_user=(user)
    @current_user = user
  end

  def current_user
    if params[:auth_token]
      @current_user ||= User.find_by(token: params[:auth_token])
    elsif session[:token]
      @current_user ||= User.where(token: session[:token], admin: true).first
    end
  end

  def logged_in?
    !current_user.nil?
  end

  def logged_in_user
    unless logged_in?
      head status: 401
    end
  end

  # Return error message if user has not allowed notifications on the app
  def has_allowed_notifications
    if user_agent["iPhone"] && !@current_user.device_token
      head status: 424
    end
  end

  def check_location
    zipcode = params[:zip]
    if zipcode && ! Location::OPERATED_ZIPCODES.include?(zipcode)
      head status: 417
    end
  end

end
