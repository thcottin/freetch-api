require 'database_cleaner'

namespace :data do
  desc "Generate feedback messages"
  task feedback_messages: :environment do
    DatabaseCleaner.clean_with(:truncation, :only => %w[feedbacks])
    FEEDBACK_MESSAGES.each do |key, values|
      values.each do |message|
        Feedback.create(driver: key, message: message)
      end
    end
  end

  desc "Generate messages for views"
  task message_views: :environment do
    DatabaseCleaner.clean_with(:truncation, :only => %w[message_views])
    MessageView.destroy_all
    MESSAGE_VIEWS.each do |key, value|
      MessageView.create(ref: key, message: value)
    end
  end

  desc "Geocode an address"
  task :geocode, [:address] => [:environment] do |t,args|
    loc = Distance.new(address: args[:address])
    loc.geocode
    p [loc.lat, loc.lng]
  end

  desc "Match a pending parker"
  task :match_parker, [:address] => [:environment] do |t,args|
    leaver = User.find_by(email: "th.cottin76@gmail.com")
    loc = Distance.new(address: args[:address])
    loc.geocode

    sweetch = MatchingHelper.match_sweetch(loc.lat, loc.lng, "leaver")
    sweetch.assign_attributes(leaver_id: leaver.id, leaver_lat: loc.lat, leaver_lng: leaver_lng)
    if sweetch.ready_to_start
      sweetch.start
      sweetch.save!
    end
  end

  desc "Sweetchers"
  task :sweetchers => :environment do
    sweetchers = User.where('count_sweetch > 0')
                      .where(created_at: Date.new(2014,05,07).to_time..Time.now)
    sweetchers.each do |u|
      p "#{u.first_name} #{u.last_name}"
    end
  end
end
