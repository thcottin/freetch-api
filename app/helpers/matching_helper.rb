module MatchingHelper

	def self.match_sweetch(driver_lat, driver_lng, user_id, user_type)
		sweetches = Sweetch.where(created_at: 10.minutes.ago.to_time..Time.now,
															(user_type + '_lat') => nil, (user_type + '_lng') => nil, state: "pending")

		# Reject the sweetch created by the same user
		sweetches.reject! { |sweetch| sweetch.leaver_id.to_i == user_id || sweetch.parker_id.to_i == user_id }
		user_location = Distance.new(lat: driver_lat.to_f, lng: driver_lng.to_f)
		unless sweetches.empty?

		  # Get locations of all sweetches
		  sweetch_locations = sweetches.map { |sweetch| sweetch.initial_location }

		  #Calculate distances of current_user wrt each sweetch
		  distances = sweetch_locations.map { |location| Distance.distance(user_location, location) }
		  min = distances.each_with_index.min
		  # Check if the Sweetch with the smallest distance is close enough from parker
		  if Distance.sweetchable(min.first)
		    return sweetches[min.last]
			end
		end
		return Sweetch.new
	end

	def self.nearest_sweetches(lat, lng, user_id)
		
		sweetches = Sweetch.select(:leaver_lat, :leaver_lng, :id).where(created_at: 10.minutes.ago.to_time..Time.now,
															('parker_lat') => nil, ('parker_lng') => nil, state: "pending")

		user_location = Distance.new(lat: lat.to_f, lng: lng.to_f)
		
		# Keep only sweetches nearby
		sweetches.reject! do |sweetch|
		  sweetch_location = sweetch.initial_location
		  !Distance.nearby(user_location, sweetch_location)
		end
	end
end
