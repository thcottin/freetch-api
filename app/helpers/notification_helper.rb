module NotificationHelper

  def self.publish_match_parker(sweetch)
    aps = { alert: "#{sweetch.leaver.first_name} is waiting for you", sound: "default" }

    data = {}
    data[:facebook_id] = sweetch.leaver.facebook_id
    data[:first_name] = sweetch.leaver.first_name
    data[:lat] = sweetch.leaver_lat
    data[:lng] = sweetch.leaver_lng
    data[:ph] = sweetch.leaver.phone if sweetch.leaver.phone

    message = {}
    message[:aps] = aps
    message[:data] = data

    publish(sweetch.parker, "Match Found", message, {})
  end

  def self.publish_match_leaver(sweetch)
    aps = { alert: "#{sweetch.parker.first_name} is coming in #{sweetch.eta}", sound: "default" }

    data = {}
    data[:facebook_id] = sweetch.parker.facebook_id
    data[:first_name] = sweetch.parker.first_name
    data[:ph] = sweetch.parker.phone if sweetch.parker.phone
    data[:eta] = sweetch.eta

    pubnub = {
      p_lat: sweetch.parker_lat,
      p_lng: sweetch.parker_lng
    }

    message = {}
    message[:aps] = aps
    message[:data] = data

    publish(sweetch.leaver, "Match Found", message, pubnub)
  end

  def self.schedule_publish_not_found(user, sweetch)
    aps = { alert: "No Sweetch buddy around, try again?", sound: "default" }

    data = {}
    data[:state] = sweetch.state

    message = {}
    message[:aps] = aps
    message[:data] = data

    response = publish(user, "Match Not Found", message, {}, 305.seconds.from_now)

    if response.has_key?("scheduled_notifications")
      push_id = response["scheduled_notifications"].first.split("/").last
      sweetch.update_column(:scheduled_push_id, push_id)
    end
  end

  def self.publish_validation(sweetch)
    # Create alert message
    aps = { :alert => "#{sweetch.leaver.first_name} has confirmed the Sweetch", :sound => "default" }

    data = {}
    data[:facebook_id] = sweetch.leaver.facebook_id
    data[:first_name] = sweetch.leaver.first_name

    message = {}
    message[:aps] = aps
    message[:data] = data

    publish(sweetch.parker, "Sweetch Validated", message, {})
  end

  def self.publish_fail(sweetch)
    # Take the id of the user who reported the problem
    feedback_association = sweetch.feedback_associations.last
    if feedback_association
      reporter = feedback_association.user
    end

    # Send notif to the other user involved in the sweetch
    receiver = (sweetch.drivers - [reporter]).first

    # Create alert message
    aps = { :alert => "#{reporter.first_name} can't make it anymore", :sound => "default" }

    data = {}
    data[:sweetch_id] = sweetch.id
    data[:sweetch_state] = sweetch.state

    message = {}
    message[:aps] = aps
    message[:data] = data

    publish(receiver, "Sweetch Failed", message, {})
  end

  # Tell UA to delete the scheduled push notification for match not found
  def self.delete_scheduled_push(sweetch)
    push_id = sweetch.scheduled_push_id
    Urbanairship.delete_scheduled_push(push_id) if push_id
  end

  # Send to UA the notification to push to iOS device
  # @param users: an array of users to sends the notification to
  # @param title: the title of the notif that the app listens for
  # @param message: the content of the notif
  # @param schedule_for: if the notification is scheduled for later
  def self.publish(user, title, message, options, schedule_for = nil)
    device_tokens = []
    if user.is_a?(User)
      device_tokens << user.device_token
    elsif user.is_a?(Array)
      device_tokens = user.map { |user| user.device_token }
    end

    notif = {}
    notif[:schedule_for] = [schedule_for] if schedule_for
    notif[:device_tokens] = device_tokens
    notif[:extra] = message[:data]
    notif[:aps] = message[:aps]
    notif[:title] = title
    notif[:device_types] = ["ios"]

    ua = Urbanairship.push(notif)
    pubnub = Publish.publish("sweetch-#{user.id}", { title: title, data: message[:data].merge(options)}) unless schedule_for
    [ua, pubnub]
  end
end
