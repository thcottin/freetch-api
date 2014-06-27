FactoryGirl.define do
  factory :leaver, class: User do |u|
    u.first_name      "Armando"
    u.last_name       "Guereca"
    u.email           "armando@example.com"
    u.facebook_id     358284
    u.token           "random-string-faking-token-for-armando"
    u.device_token    "device-token-string"
    u.count_sweetch   2
  end

  factory :parker, class: User do |u|
    u.first_name      "Bob"
    u.last_name       "Builder"
    u.email           "bob@example.com"
    u.facebook_id     4828473
    u.token           "random-string-faking-token-for-bob"
    u.device_token    "device-token-for-parker"
    u.count_sweetch   1
    u.customer_token   "cus_3eTPd2kJ7HRfqi"
  end

  factory :customer, class: User do |u|
    u.first_name      "Madame"
    u.last_name       "Michu"
    u.email           "michu@example.com"
    u.facebook_id     4828473
    u.token           "random-string-faking-token-for-madame-michu"
    u.device_token    "device-token-for-customer"
    u.count_sweetch   1
    u.customer_token   "cus_3eTPd2kJ7HRfqi"
  end

  # factory :spot_la_motte_picquet, class: Spot do |s|
  #   s.lat     48.8476
  #   s.lng     2.2987
  # end

  factory :sweetch_in_progress, class: Sweetch do |s|
    s.leaver_lat      37.7490742
    s.leaver_lng      -122.4203495
    s.parker_lat      37.75
    s.parker_lng      -122.4303495
    s.state           "in_progress"
  end

  factory :message, class: MessageView do |m|
    m.ref              "notif_leaver"
    m.message          "will arrive in 5 minutes"
  end

  factory :feedback, class: Feedback do |f|
    f.driver  "PARKER"
    f.message "I found another spot"
  end
end
