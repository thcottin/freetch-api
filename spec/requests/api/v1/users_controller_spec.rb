require 'spec_helper'
require 'request_spec_helper'

describe API::V1::UsersController do

	before { @user = FactoryGirl.build(:leaver) }

	describe "GET /show" do

		before { @customer = FactoryGirl.create(:customer, customer_token: "cus_3j6NSXi8nNZLj8") }

		it "returns a value using token" do
			allow(PaymentHelper).to receive(:retrieve_customer).and_return( { "last4" => "4242", "type" => "Visa" })
			get me_api_v1_users_url, { auth_token: @customer.token }
			expect(json_response["id"]).to eq(@customer.id)
			expect(json_response["card"]["last4"]).not_to be_nil
			expect(json_response["card"]["type"]).not_to be_nil
		end
	end

	describe "POST /create" do

		context "when information valid" do

			it "stores user and returns user" do
				expect{
					post api_v1_users_url, @user.as_json
				}.to change{ User.count }.by(1)
				expect(json_response["user"]["email"]).to eq(@user.email)
				expect(json_response["user"]["created"]).to eq(true)
				expect(json_response["user"]["is_customer"]).to eq(false)
			end

			context "user already exists and is customer" do
				before do
					@user.customer_token = "cus_tokzl"
					@user.save
				end

				it "should return full user information" do
					allow(PaymentHelper).to receive(:retrieve_customer).and_return( { "last4" => "4242", "type" => "Visa" })
					post api_v1_users_url, @user.as_json
					expect(json_response["user"]["card"]["last4"]).to eq("4242")
					expect(json_response["user"]["card"]["type"]).to eq("Visa")
				end
			end
		end

		context "when user already exist" do

			it "updates user token" do
				user = FactoryGirl.create(:leaver)
				user.token = "new_token"
				user.first_name = "Tuco"
				expect {
					post api_v1_users_url, user.as_json(except: [:id])
				}.not_to change { User.count }

				expect(user.reload.token).to eq("new_token")
				expect(json_response["user"]["created"]).to be_nil
			end
		end
	end

	describe "PATCH /update" do

		before do
			@user.save
			stub_twilio
		end

		context "when user gives his credit card" do
			it "updates Stripe token" do
				expect(PaymentHelper).to receive(:create_customer).with(@user)
				card_token = "card_token"
				patch api_v1_user_url(@user), { auth_token: @user.token, card_token: card_token }
			end

			it "sends alert to founders" do
				allow(PaymentHelper).to receive(:create_customer)
				allow(MetricsHelper).to receive(:card_given)
				card_token = "card_token"
				patch api_v1_user_url(@user), { auth_token: @user.token, card_token: card_token }
			end
		end

		context "when user is updated with a device_token" do
			it "registers device for notifications" do
				expect(Urbanairship).to receive(:register_device)
				patch api_v1_user_url(@user), auth_token: @user.token, device_token: @user.device_token
			end
		end

		context "when user give his phone number" do
			it "returns the number" do
				allow(MetricsHelper).to receive(:phone_given)
				patch api_v1_user_url(@user), auth_token: @user.token, phone: "4155290257"
				expect(json_response["user"]["phone"]).to eq("4155290257")
			end

			it "send phone to mixpanel and sms to founders" do
				expect(MetricsHelper).to receive(:phone_given).with(@user)
				patch api_v1_user_url(@user), auth_token: @user.token, phone: "4155290257"
			end
		end
	end
end
