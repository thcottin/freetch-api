module StubsHelper

  def stub_notifications
    allow(NotificationHelper).to receive(:publish).and_return({ scheduled_notifications: [] })
  end

  def stub_mixpanel
    allow_any_instance_of(Mixpanel::Tracker).to receive(:track).and_return(true)
    allow_any_instance_of(Mixpanel::People).to receive(:set).and_return(true)
  end

  def stub_payment
    allow_any_instance_of(Sweetch).to receive(:charge_and_update_credits)
    allow_any_instance_of(Sweetch).to receive(:refund_and_update_credits)
  end
  
  def stub_twilio
    allow(Alert).to receive(:signup)
    allow(Alert).to receive(:card_given)
    allow(Alert).to receive(:phone_given)
    allow(Alert).to receive(:messages)
  end
end
