require 'spec_helper'
require 'request_spec_helper'

describe "Mixpanel", integration: true do
  context "User created" do
    before do
      @tracker = Mixpanel::Tracker.new(MIXPANEL_TOKEN)
      distinct_id = random_string
      @tracker.track(distinct_id, "App Opened")
      User.skip_callback("create",:after,:track_created_user)
      @user = FactoryGirl.create(:leaver, :mixpanel_id => distinct_id)
      @tracker.people.delete_user(@user.id)
    end

    it "should send tracker to Mixpanel" do
      expect(MetricsHelper.created_user(@user)).to eq(true)
    end
  end

  context "Sweetch failure" do
    before do
      stub_payment
      stub_notifications
      @parker = FactoryGirl.create(:parker)
      @leaver = FactoryGirl.create(:leaver)
      @sweetch = Sweetch.create(parker_id: @parker.id, leaver_id: @leaver.id, state: "in_progress")
      Feedback.create(message: "I had to leave")
      FeedbackAssociation.create(feedback_id: 1, user_id: @leaver.id, sweetch_id: @sweetch.id)
    end

    it "should send failure events" do
      @sweetch.fail
    end
  end
end

def random_string
  (0...8).map{ ('A'..'Z').to_a[rand(26)]  }.join
end
