class Location < ActiveRecord::Base
  belongs_to :user

  OPERATED_ZIPCODES = ['94110']
end