require 'spec_helper'
require 'request_spec_helper'

# Run these tests to see if the device associated with the token below
# receives the notification.

# This device token belongs to Thomas with Sweetch app in dev mode

describe 'Notifications', integration: true do
  before do
    allow(Urbanairship).to receive(:register_device)
    allow(NotificationHelper).to receive(:schedule_publish_not_found)
  end

  before do
    @leaver = FactoryGirl.create(:leaver, device_token: "CBC9CB91FB2E2B737C9CD7C3886836FCEBE651CC98B3536225049214D13E1EAD")
    @parker = FactoryGirl.create(:parker, device_token: "CBC9CB91FB2E2B737C9CD7C3886836FCEBE651CC98B3536225049214D13E1EAD")
    @sweetch = FactoryGirl.create(:sweetch_in_progress, leaver_id: @leaver.id, parker_id: @parker.id)
  end

  describe "Publish a match found" do

    it "should send notification with alert and sound to parker" do
      response = NotificationHelper.publish_match_parker(@sweetch)
      p response
      # expect(response["push_id"]).not_to be_nil
    end
  end

  describe "Publish a sweetch validation" do

    before { @sweetch.update(state: "validated") }

    it "should send notification with alert and sound to parker" do
      response = NotificationHelper.publish_validation(@sweetch)
      expect(response["push_id"]).not_to be_nil
    end
  end

  describe "Publish a failed sweetch" do

    before do
      @sweetch.update(state: "failed")
      @feedback = FactoryGirl.create(:feedback)
      @sweetch.feedback_associations.create(feedback_id: @feedback.id, user_id: @sweetch.parker_id)
    end

    it "should send notification with alert and sound" do
      response = NotificationHelper.publish_fail(@sweetch)
      expect(response["push_id"]).not_to be_nil
    end
  end
end
