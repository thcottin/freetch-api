require 'net/http'
require 'uri'

class Distance
  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming

  attr_accessor :lat, :lng, :address, :available, :zipcode

  validates :lat, presence: true
  validates :lng, presence: true

  MAXDISTANCE = 4000

  def initialize(attributes = {})
    @lat = attributes[:lat] if attributes[:lat].is_a?(Float)
    @lng = attributes[:lng] if attributes[:lng].is_a?(Float)
    @address = attributes[:address]
    @available = true
  end

  # turns address into coordinates using google maps api
  def geocode
    uri = URI::HTTP.build(:scheme => 'http',
                          :host   => 'maps.googleapis.com',
                          :path   => '/maps/api/geocode/json',
                          :query  => URI.encode_www_form(:address => "#{self.address}",
                                                         :sensor => false))

    response = Net::HTTP.get_response(uri)
    if response.is_a?(Net::HTTPSuccess)
      json = JSON.parse(response.body)
      Rails.logger.error json
      location = json["results"].first["geometry"]["location"]
      self.lat = location["lat"]
      self.lng = location["lng"]
    end
    self
  end

  # turns coordinates into address using google maps reverse geocode api
  def reverse_geocode
    uri = URI::HTTP.build(:scheme => 'http',
                            :host   => 'maps.googleapis.com',
                            :path   => '/maps/api/geocode/json',
                            :query  => URI.encode_www_form(:latlng => "#{self.lat},#{self.lng}",
                                                           :sensor => true))

    response = Net::HTTP.get_response(uri)

    if response.is_a?(Net::HTTPSuccess)
      json = JSON.parse(response.body)
      Rails.logger.error json
      begin
        self.address = json["results"].first["formatted_address"]
        self.zipcode = json["results"].first["address_components"].last["short_name"]
      rescue Exception => e
        Rails.logger.error e
      end
    end
    self
  end

  def self.eta(from, to)
    uri = URI::HTTP.build(:scheme => 'http',
                          :host   => 'maps.googleapis.com',
                          :path   => '/maps/api/directions/json',
                          :query  => URI.encode_www_form(:origin => "#{from.lat},#{from.lng}", :destination => "#{to.lat},#{to.lng}",
                                                         :sensor => true))

    response = Net::HTTP.get_response(uri)
    if response.is_a?(Net::HTTPSuccess)
      json = JSON.parse(response.body)
      duration = json["routes"].first["legs"].first["duration"]["text"]
    else
      false
    end
  end

  def self.distance (pointA, pointB)
    a = [pointA.lat, pointA.lng]
    b = [pointB.lat, pointB.lng]

    rad_per_deg = Math::PI/180  # PI / 180
    rkm = 6371                  # Earth radius in kilometers
    rm = rkm * 1000             # Radius in meters

    dlon_rad = (b[1]-a[1]) * rad_per_deg  # Delta, converted to rad
    dlat_rad = (b[0]-a[0]) * rad_per_deg

    lat1_rad, lon1_rad = a.map! {|i| i * rad_per_deg }
    lat2_rad, lon2_rad = b.map! {|i| i * rad_per_deg }

    a = Math.sin(dlat_rad/2)**2 + Math.cos(lat1_rad) * Math.cos(lat2_rad) * Math.sin(dlon_rad/2)**2
    c = 2 * Math.asin(Math.sqrt(a))

    rm * c # Delta in meters
  end

  def self.sweetchable (distance)
    distance < MAXDISTANCE
  end

  def check_zipcode
    unless ZIPCODES.include?(self.reverse_geocode.zipcode)
      self.available = false
    end
  end

  def persisted?
    false
  end

  def self.nearby (locationA, locationB)
    self.distance(locationA, locationB) < MAXDISTANCE
  end
end
