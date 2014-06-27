require "spec_helper"
require "request_spec_helper"

describe "Payment Helper", integration: true do

  before {
    allow(NotificationHelper).to receive(:schedule_publish_not_found)
  }

  describe "Create Customer" do
  end

  describe "Retrieve Customer" do
    before { @customer = FactoryGirl.create(:customer, customer_token: "cus_3j6NSXi8nNZLj8")}
    it "should return card of customer" do
      response = PaymentHelper.retrieve_customer(@customer)
      expect(response["last4"]).to eq("4242")
      expect(response["type"]).to eq("Visa")
    end
  end

  describe "Create Transaction" do
    before(:each) do
      @parker = FactoryGirl.create(:parker, customer_token: "cus_3j6NSXi8nNZLj8")
      @leaver = FactoryGirl.create(:leaver)
      @sweetch = Sweetch.create(leaver_id: @leaver.id, parker_id: @parker.id)
    end

    context "parker has more than 5 credits" do
      before { @parker.update_attribute(:credits, 10)}

      it "doesnt send request to sripe" do
        expect(Stripe::Charge).not_to receive(:create)
        response = PaymentHelper.create_transaction(@parker, @sweetch)
        expect(response[:status]).to be(true)
        expect(response[:amount_charged]).to be(0)
        # expect(@parker.reload.credits).to eq(10 - PaymentHelper::SWEETCH_PRICE)
      end
    end

    context "parker has less than 5 credits" do
      before { @parker.update_attribute(:credits, 3)}

      it "sends transaction request to Stripe" do
        response = PaymentHelper.create_transaction(@parker, @sweetch)
        expect(response[:status]).to be(true)
        expect(response[:amount_charged]).to be((PaymentHelper::SWEETCH_PRICE - 3) * PaymentHelper::FACTOR)
        expect(@sweetch.reload.charge_token).not_to be_nil
      end
    end
  end

  describe "Refund transaction" do
    before do
      @parker = FactoryGirl.create(:parker, customer_token: "cus_3j6NSXi8nNZLj8")
      @leaver = FactoryGirl.create(:leaver)
      @sweetch = Sweetch.create(leaver_id: @leaver.id, parker_id: @parker.id)
    end

    context "user had less than 5 credits" do
      before do
        @parker.update_attribute(:credits, 3)
        PaymentHelper.create_transaction(@parker, @sweetch)
      end

      it "sends refund request to Stripe" do
        response = PaymentHelper.refund_transaction(@parker, @sweetch)
        expect(response[:status]).to be(true)
        expect(response[:amount_refunded]).to be((PaymentHelper::SWEETCH_PRICE - 3) * PaymentHelper::FACTOR)
      end
    end

    context "user had more than 5 credits" do
      before do
        @parker.update_attribute(:credits, 10)
        PaymentHelper.create_transaction(@parker, @sweetch)
      end

      it "doesnt send request to Stripe" do
        expect(Stripe::Charge).not_to receive(:retrieve)
        response = PaymentHelper.refund_transaction(@parker, @sweetch)
        expect(response[:status]).to be(true)
        expect(response[:amount_refunded]).to be(0)
      end
    end
  end
end
