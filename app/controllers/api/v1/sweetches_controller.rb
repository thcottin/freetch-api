class API::V1::SweetchesController < ApplicationController

  before_action :logged_in_user
  before_action :check_location, :only => [:create]
  before_action :has_allowed_notifications

  # action triggered when the user clicks on "leave"
  # creates a sweetch in a "pending" state
  
  def index
    lat = params[:lat]
    lng = params[:lng]
    zipcode = params[:zip]
    covered_area = false

    if lat && lng
      @sweetches = MatchingHelper.nearest_sweetches(lat, lng, current_user.id)
    else
      render json: { error: "Missing required parameters lat or lng" } and return
    end

    if Location::OPERATED_ZIPCODES.include?(zipcode)
      covered_area = true
    end

    render json: { results: @sweetches, covered_area: covered_area }
  end

  def create
    leaver_lat = params[:leaver_lat]
    leaver_lng = params[:leaver_lng]
    parker_lat = params[:parker_lat]
    parker_lng = params[:parker_lng]
    address = params[:address]
    zipcode = params[:zip]
    options = {}

    # Set last known user location
    current_user.address = address
    current_user.zipcode = zipcode
    current_user.save!

    # Monitor user activity
    # MetricsHelper.sweetch_requested(current_user)

    # Create a new sweetch or find a pending one
    if leaver_lat && leaver_lng
      # Current user is leaving
      @sweetch = MatchingHelper.match_sweetch(leaver_lat, leaver_lng, current_user.id, "leaver")
      @sweetch.assign_attributes(leaver_id: current_user.id, leaver_lat: leaver_lat, leaver_lng: leaver_lng)
      @sweetch.matched_with = @sweetch.parker
    elsif parker_lat && parker_lng
      # Current user is parking
      @sweetch = MatchingHelper.match_sweetch(parker_lat, parker_lng, current_user.id, "parker")
      @sweetch.assign_attributes(parker_id: current_user.id, parker_lat: parker_lat, parker_lng: parker_lng)
      @sweetch.matched_with = @sweetch.leaver
    else
      render json: { error: "Missing required parameters leaver_lat or leaver_lng" } and return
    end

    # Start process and send notif if sweetch ready to start
    if @sweetch.ready_to_start && @sweetch.can_start?
      # Ask google apis for ETA
      @sweetch.get_eta
      # Start sweetch
      @sweetch.start
    end

    @sweetch.save!

    render json: { sweetch: @sweetch.as_resource(options) }
  end

  def update
    @sweetch = Sweetch.find_by(id: params[:id])
    options = {}

    case params[:state]
    when "cancelled"
      @sweetch.cancel
    when "in_progress"
      @sweetch.get_eta
      @sweetch.start
      options[:leaver] = @sweetch.leaver.as_resource(locate: false)
    when "validated"
      @sweetch.leaver.count_sweetch += 1
      @sweetch.parker.count_sweetch += 1
      @sweetch.validate
      @sweetch.leaver.save
      @sweetch.parker.save
    when "failed"
      # Store error message
      @sweetch.feedback_associations.create(user_id: current_user.id, feedback_id: params[:feedback_id])
      @sweetch.fail
    when "contested"
      @sweetch.feedback_associations.create!(user_id: current_user.id, feedback_id: params[:feedback_id])
      @sweetch.contest
    end

    @sweetch.save

    render json: { sweetch: @sweetch.as_resource }.merge(options)
  end
end
