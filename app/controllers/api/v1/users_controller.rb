class API::V1::UsersController < ApplicationController

  before_action :logged_in_user, only: [:show]

  def show
    # identify user from received parameters
    @user = User.find_by(:token => params[:auth_token])
    options = {}

    if @user
      if @user.customer?
        options[:card] = true
      end
      render json: @user.as_resource(options)
    else
      render json: { error: "User was not found" }
    end
  end

  def create
    @user = User.find_by(facebook_id: params[:facebook_id])
    # if we already have the user, we are just doing an update
    if @user
      params[:card] = true
      update and return
    else
      @user = User.new do |user|
        user.first_name = params[:first_name]
        user.last_name = params[:last_name]
        user.email = params[:email]
        user.token = params[:token]
        user.facebook_id = params[:facebook_id]
        user.device_token = params[:device_token]
        user.location = @user_location
        user.count_sweetch = 0
        user.mixpanel_id = params[:mixpanel_id]
      end
    end

    if @user.save
      render json: { user: @user.as_resource(created: true) }
    else
      render json: { errors: @user.errors}
    end

  end

  # Action always trigerred by the create action when the user already exists
  # @user defined in create action
  def update
    @user ||= User.find(params[:id])

    facebook_token = params[:token]
    device_token = params[:device_token]
    card_token = params[:card_token]
    phone = params[:phone]
    lat = params[:lat].to_f
    lng = params[:lng].to_f
    options = {}

    # Update the facebook token from a POST request to the create action
    if @user.email == params[:email] && facebook_token != @user.token
      @user.token = params[:token]
    end

    # Update phone number
    if phone
      @user.phone = phone 
      MetricsHelper.phone_given(@user)
      Alert.phone_given(@user)
    end

    # Update the payment token from a PATCH request
    @user.card_token = card_token if card_token

    # Update or initiate the device_token used to identify the ios user on APNS
    if device_token && (device_token != @user.device_token)
      @user.device_token = device_token
    end

    if lat != 0.0 && lng != 0.0
      # Save in a location database the location of the user
      @user.locations.create(lat: lat, lng: lng)
    end

    options[:card] = params[:card] if params[:card]

    @user.register_for_notifications = true if device_token
    @user.save

    render json: { user: @user.as_resource(options) }
  end

end
