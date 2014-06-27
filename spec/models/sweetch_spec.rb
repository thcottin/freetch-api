require 'spec_helper'

describe Sweetch do
  before { @sweetch = Sweetch.new }
  before { allow(NotificationHelper).to receive(:publish).and_return( :scheduled_notifications => [] ) }
	subject { @sweetch }

	it { should respond_to(:parker_id) }
  it { should respond_to(:leaver_id) }
	it { should respond_to(:state) }
	it { should respond_to(:parker_lat) }
	it { should respond_to(:parker_lng) }
	it { should respond_to(:leaver_lat) }
	it { should respond_to(:leaver_lng) }

	context "when leaver_id is present" do
    before do
      @leaver = FactoryGirl.create(:leaver)
      @sweetch.leaver_id = @leaver.id
      @sweetch.save
    end

    it "has state pending" do
      expect(@sweetch.state).to eq("pending")
    end
	end

	context "when parker_id is present" do
    before do
      @parker = FactoryGirl.create(:parker)
      @sweetch.parker_id = @parker.id
      @sweetch.save
    end

    it "has state pending" do
      expect(@sweetch.state).to eq("pending")
    end
	end

  describe "Sweetch validation" do

    before do
      @leaver = FactoryGirl.create(:leaver)
      @parker = FactoryGirl.create(:parker)
      @sweetch = Sweetch.create(parker_id: @parker.id, leaver_id: @leaver.id, state: "in_progress")
      stub_mixpanel
      stub_notifications
    end

    context "when parker has less than 5 credits" do

      it "triggers financial transaction and update credits" do
        expect(PaymentHelper).to receive(:create_transaction).with(@parker, @sweetch).and_return({ status: true, amount_charged: 500 })
        expect {
          @sweetch.validate
        }.to change{ @leaver.reload.credits }.by(4)
        expect(@parker.reload.credits).to eq(0)
      end
    end

    context "when parker has more than 5 credits" do

      before do
        @parker.credits = 10
        @parker.save
        @sweetch.reload
      end

      it "triggers financial transaction and update credits" do
        expect(PaymentHelper).to receive(:create_transaction).with(@parker, @sweetch).and_return( { status: true, amount_charged: 0 })
        expect {
          expect {
            @sweetch.validate
          }.to change{ @leaver.reload.credits }.by(4)
        }.to change{ @parker.reload.credits }.by(-5)
      end
    end
  end
end
