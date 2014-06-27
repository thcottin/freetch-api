require 'spec_helper'
require 'request_spec_helper'

describe API::V1::SweetchesController, type: :controller do

  before do
    @leaver = FactoryGirl.create(:leaver)
    @parker = FactoryGirl.create(:parker)
    stub_notifications
    stub_mixpanel
    allow_any_instance_of(Sweetch).to receive(:get_eta)
  end

  describe "Authentication" do
    context "When no token provided" do
      it "should deny access" do
        post :create
        expect(response.status).to eq(401)
      end
    end

    context "When invalid token provided" do
      it "should deny access" do
        post :create, auth_token: "blabla"
        expect(response.status).to eq(401)
      end
    end

    context "When valid token provided" do
      it "should authorize access" do
        expect{
          post :create, auth_token: @leaver.token, leaver_lat: 37.7490742, leaver_lng: -122.4203495
        }.to change{Sweetch.count }.by(1)
        expect(response).to be_success
      end
    end

    context "When invalid location provided" do
      it "should deny access" do
        post :create, auth_token: @leaver.token, leaver_lat: 48, leaver_lng: 2, zip: 73118
        expect(response.status).to eq(417)
      end
    end
  end

  describe "User is on park screen" do

    before do
      @parker_params = { lat: 37.74907, lng: -122.420134, parker: true, auth_token: @parker.token}
    end

    context "and there is no users leaving around him" do
      it "should return fake drivers" do
        get :index, @parker_params
        # returns the 3 fake sweetches
        expect(json_response["results"].count).to eq(3)
      end
    end

    context "and there are users leaving around him" do
      it "should return locations of pending sweetches of leavers" do
        @sweetch_leaver1 = Sweetch.create!(leaver_id: 1, leaver_lat: 37.74907, leaver_lng: -122.42023)
        @sweetch_leaver2 = Sweetch.create!(leaver_id: 2, leaver_lat: 37.74910, leaver_lng: -122.42034)
        get :index, @parker_params
        expect(json_response["results"].count).to eq(5) #returns 2 defined in the before + 3 fake sweetches
      end
    end

    context "and is not in the good neighborhood" do
      it "should specify the area is covered" do
        get :index, @parker_params.merge(zip: "94110")
        expect(json_response["covered_area"]).to eq(true)
      end
    end

    context "and is not in the good neighborhood" do
      it "should specify the area is not covered" do
        get :index, @parker_params.merge(zip: "74110")
        expect(json_response["covered_area"]).not_to eq(true)
      end
    end
  end

  describe "User clicks on leave" do
    before do
      # This spot is located at 25 rue fremicourt, Paris
      @leaver_params = { auth_token: @leaver.token, leaver_lat: 37.7490742, leaver_lng: -122.4203495, address: "1495 Valencia St", zip: "94110" }
    end

    context "and has not allowed notifications" do

      before { @leaver.update_attribute(:device_token, nil) }

      it "should return error message" do
        allow(request).to receive(:user_agent).and_return('iPhone')
        expect { 
          post :create, @leaver_params
        }.not_to change{ Sweetch.count }
        expect(response.status).to eq(424)
      end
    end

    context "and has no credit card" do
      before { @leaver.update_attribute(:customer_token, nil) }
    end

    context "when a match is possible" do

      before do
        @parker_params = { auth_token: @parker.token, parker_lat: 37.7490742, parker_lng: -122.4203495 }
        @sweetch = Sweetch.create!(parker_id: @parker.id, parker_lat: @parker_params[:parker_lat], parker_lng: @parker_params[:parker_lng])
      end

      it "should update user last known location" do
        post :create, @leaver_params
        expect(@leaver.reload.address).to eq("1495 Valencia St")
        expect(@leaver.zipcode).to eq("94110")
      end

      it "should send a notification to parker" do
        expect(NotificationHelper).to receive(:delete_scheduled_push).with(@sweetch)
        expect(NotificationHelper).to receive(:publish_match_parker).with(@sweetch)
        expect(NotificationHelper).not_to receive(:publish_match_leaver).with(@sweetch)
        post :create, @leaver_params
      end

=begin
      it "should track the sweetch progress" do
        expect(MetricsHelper).to receive(:sweetch_in_progress)
        post :create, @leaver_params
      end

      it "should track the sweetch request from leaver" do
        expect(MetricsHelper).to receive(:sweetch_requested).with(@leaver)
        post :create, @leaver_params
      end
=end
      it "should return the sweetch in state progress" do
        expect{ post :create, @leaver_params }.not_to change{ Sweetch.count }
        expect(json_response["sweetch"]["id"]).to eq(@sweetch.id)
        expect(json_response["sweetch"]["leaver_facebook_id"]).to eq(@sweetch.reload.leaver.facebook_id)
        expect(json_response["sweetch"]["parker_facebook_id"]).to eq(@sweetch.parker.facebook_id)
        expect(@sweetch.reload.state).to eq("in_progress")
      end
    end

    context "when match is not possible" do

      context "because no pending sweetch" do

        it "should create a new sweetch" do
          expect{ post :create, @leaver_params }.to change{ Sweetch.count }.by(1)
        end

        it "should schedule a match not found notification" do
          expect(NotificationHelper).to receive(:schedule_publish_not_found)
          expect(NotificationHelper).not_to receive(:publish_match)
          post :create, @leaver_params
        end

        it "should return the sweetch in state pending" do
          post :create, @leaver_params
          expect(json_response["sweetch"]["id"]).not_to be_nil
          expect(json_response["sweetch"]["state"]).to eq("pending")
        end
      end

      context "because pending sweetch is too far" do
        before do
          @parker_params = { auth_token: @parker.token, parker_lat: 48.848998, parker_lng: 2.555555 }
          @sweetch = Sweetch.create!(parker_id: @parker.id, parker_lat: @parker_params[:parker_lat], parker_lng: @parker_params[:parker_lng])
        end

        it "should create a new sweetch" do
          expect{ post :create, @leaver_params }.to change{ Sweetch.count }.by(1)
        end

        it "should schedule a match not found notification" do
          expect(NotificationHelper).to receive(:schedule_publish_not_found)
          expect(NotificationHelper).not_to receive(:schedule_publish_not_found).with(@leaver, @sweetch)
          expect(NotificationHelper).not_to receive(:publish_match).with(@sweetch)
          post :create, @leaver_params
        end

        it "should return the sweetch in state pending" do
          post :create, @leaver_params

          expect(json_response["sweetch"]["id"]).not_to eq(@sweetch.id)
          expect(@sweetch.reload.state).to eq("pending")
          expect(@sweetch.leaver_id).to be_nil

          new_sweetch = Sweetch.find_by(leaver_id: @leaver.id)
          expect(json_response["sweetch"]["id"]).to eq(new_sweetch.id)
          expect(json_response["sweetch"]["state"]).to eq("pending")
        end
      end

      context "because parker equals leaver" do
        before do
          @parker_params = { auth_token: @parker.token, parker_lat: 48.848998, parker_lng: 2.297695 }
          @leaver_params[:auth_token] = @parker.token
          @sweetch = Sweetch.create!(parker_id: @parker.id, parker_lat: @parker_params[:parker_lat], parker_lng: @parker_params[:parker_lng])
        end

        it "should not match" do
          expect {
            post :create, @leaver_params
          }.to change { Sweetch.count }.by(1)
          expect(json_response["sweetch"]["state"]).to eq("pending")
        end
      end
    end

    context "but cancels before finding match" do

      before do
        @sweetch = Sweetch.create(leaver_id: @leaver.id, leaver_lat: @leaver_params[:leaver_lat], leaver_lng: @leaver_params[:leaver_lng])
      end

      it "should cancel sweetch" do
        patch :update, { state: "cancelled", auth_token: @leaver.token, id: @sweetch.id }
        expect(@sweetch.reload.state).to eq("cancelled")
      end

      it "should delete the scheduled not found notification" do
        expect(NotificationHelper).to receive(:delete_scheduled_push).with(@sweetch)
        patch :update, { state: "cancelled", auth_token: @leaver.token, id: @sweetch.id, id: @sweetch.id }
      end
    end
  end

  describe "Leaver confirms the Sweetch" do

    before do
      @sweetch = Sweetch.create(parker_id: @parker.id, leaver_id: @leaver.id, state: "in_progress")
      @parker.update(credits: PaymentHelper::SWEETCH_PRICE)
    end

    it "should change state to validated" do
      expect {
        patch :update, auth_token: @leaver.token, id: @sweetch.id, state: "validated"
      }.to change{ @sweetch.reload.state }.from("in_progress").to("validated")
    end

    it "should increment count sweetch" do
      expect { expect{
        patch :update, auth_token: @leaver.token, id: @sweetch.id, state: "validated"
      }.to change{ @sweetch.leaver.reload.count_sweetch}.by(1)
      }.to change{ @sweetch.parker.reload.count_sweetch}.by(1)
    end

    it "should return the sweetch in state validated" do
      patch :update, auth_token: @leaver.token, id: @sweetch.id, state: "validated"
      expect(json_response["sweetch"]["state"]).to eq("validated")
    end

    it "should update user credits" do
      patch :update, auth_token: @leaver.token, id: @sweetch.id, state: "validated"
      expect(@parker.reload.credits).to eq(0)
      expect(@leaver.reload.credits).to eq(0.8 * PaymentHelper::SWEETCH_PRICE)
    end

    it "should send validation notification to parker" do
      expect(NotificationHelper).to receive(:publish_validation).with(@sweetch)
      patch :update, auth_token: @leaver.token, id: @sweetch.id, state: "validated"
    end
  end

  describe "Leaver reports problem" do

    before do
      @sweetch = Sweetch.create(parker_id: @parker.id, leaver_id: @leaver.id, state: "in_progress")
      @feedback = Feedback.create(message: "I had to leave my spot")
    end

    it "should store the error message" do
      patch :update, { auth_token: @leaver.token, id: @sweetch.id, state: "failed", feedback_id: @feedback.id }

      sweetch_feedback = @sweetch.feedbacks.first
      user_feedback = @leaver.feedbacks.first

      # Test that all feedbacks are the same and are associated with each model
      expect(sweetch_feedback).to eq(@feedback)
      expect(user_feedback).to eq(@feedback)
    end

    it "should return sweetch in state failed" do
      patch :update, { auth_token: @leaver.token, id: @sweetch.id, state: "failed", feedback_id: @feedback.id }
      expect(@sweetch.reload.state).to eq("failed")
      expect(json_response["sweetch"]["state"]).to eq("failed")
    end

    it "should send failed notification to parker" do
      expect(NotificationHelper).to receive(:publish_fail).with(@sweetch)
      patch :update, { auth_token: @leaver.token, id: @sweetch.id, state: "failed", feedback_id: @feedback.id }
    end

    context "When Parker reports problem" do
      context "when sweetch is in progress" do

        before { @feedback = Feedback.create(message: "I found another spot") }

        it "should change sweetch state to failed" do
          # expect(MetricsHelper).to receive(:sweetch_failed).with(@sweetch)

          patch :update, { id: @sweetch.id, auth_token: @parker.token, state: "failed", feedback_id: @feedback.id }

          expect(@sweetch.reload.state).to eq("failed")
          # Check that feedback_associations table does the mapping btn a sweetch, a user and a feedback
          sweetch_feedback = @sweetch.feedbacks.first
          user_feedback = @parker.feedbacks.first

          # Test that all feedbacks are the same and are associated with each model
          expect(sweetch_feedback).to eq(@feedback)
          expect(user_feedback).to eq(@feedback)

          # Test that we return the sweetch object to leaver
          expect(json_response["sweetch"]["state"]).to eq("failed")
        end

        it "should notify leaver of sweetch cancel" do
          # Check the logs to see result, tail -f log/test.log | grep push
          patch :update, { id: @sweetch.id, auth_token: @parker.token, state: "failed", feedback_id: @feedback.id }
        end
      end

      context "after sweetch has been validated" do

        before do
          @feedback = Feedback.create(message: "Payment contested")
          @sweetch.update(state: "validated")
        end

        it "should store error message" do
          # expect(MetricsHelper).to receive(:sweetch_contested).with(@sweetch)

          patch :update, { id: @sweetch.id, auth_token: @parker.token, state: "contested", feedback_id: @feedback.id }

          expect(@sweetch.reload.state).to eq("contested")

          # Check that feedback_associations table does the mapping btn a sweetch, a user and a feedback
          sweetch_feedback = @sweetch.feedbacks.first
          user_feedback = @parker.feedbacks.first

          # Test that all feedbacks are the same and are associated with each model
          expect(sweetch_feedback).to eq(@feedback)
          expect(user_feedback).to eq(@feedback)

          # Test that we return the sweetch object to leaver
          expect(json_response["sweetch"]["state"]).to eq("contested")
        end

        context "when parker had less than 5 credits" do

          it "does refund transaction and credits" do
            expect(PaymentHelper).to receive(:refund_transaction).with(@parker, @sweetch).and_return( { status: true, amount_refunded: 200 })
            expect expect {
              patch :update, { id: @sweetch.id, auth_token: @parker.token, state: "contested", feedback_id: 1 }
            }.not_to change{ @leaver.reload.credits }
            expect(@sweetch.reload.state).to eq("contested")
            expect(@parker.reload.credits).to eq(3)
          end
        end

        context "when parker had more than 5 credits" do

          before { @parker.update_attribute(:credits, 10) }

          it "triggers financial transaction and update credits" do
            expect(PaymentHelper).to receive(:refund_transaction).with(@parker, @sweetch).and_return( { status: true, amount_refunded: 0 })
            expect {
              expect {
                patch :update, { id: @sweetch.id, auth_token: @parker.token, state: "contested", feedback_id: 1 }
              }.not_to change{ @leaver.reload.credits }
            }.to change{ @parker.reload.credits }.by(5)
          end
        end
      end
    end
  end
end
