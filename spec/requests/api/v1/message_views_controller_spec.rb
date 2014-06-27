require 'spec_helper'
require 'request_spec_helper'

describe API::V1::MessageViewsController do

	before { @display = FactoryGirl.create(:message) }

	describe "GET /show" do

		it "returns all the messages view table" do
			get api_v1_message_views_url
			expect(json_response).not_to be_nil
		end

	end
end
