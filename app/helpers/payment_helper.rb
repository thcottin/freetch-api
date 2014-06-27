module PaymentHelper

  SWEETCH_PRICE = 5
  FREE_CREDITS = 5
  FACTOR = 100

  def self.create_customer(user)
    customer = Stripe::Customer.create(
      :description => user.first_name + ' ' + user.last_name + ' (' + user.email + ')',
      :card => user.card_token,
      :email => user.email,
      :validate => false
    )

    user.card_token = nil
    user.customer_token = customer.id
    user.credits += FREE_CREDITS
    user.save!
  end

  def self.retrieve_customer(user)
    begin
      customer = Stripe::Customer.retrieve(user.customer_token)

      if customer.cards.count > 0
        card = customer.cards.data.first
        return card
      end

    rescue Stripe::InvalidRequestError => e
      Rails.logger.error "[STRIPE_CUSTOMER_ERROR] #{e}"
    end
  end

  def self.create_transaction(user, sweetch)
    # Amount to charge taking into account number of sweetch credits
    amount = user.amount_to_charge * FACTOR
    if amount == 0
      return { status: true, amount_charged: 0 }
    end

    begin
      # Charge customer on Stripe.com
      charge = Stripe::Charge.create(
        :amount => amount,
        :currency => "usd",
        :customer => user.customer_token,
        :description => "Charges for Sweetching with #{sweetch.leaver.first_name}"
      )

      sweetch.update_attribute(:charge_token, charge.id)
      { status: charge.paid, amount_charged: charge.amount.to_i }
    rescue Stripe::CardError => e
      # Since it's a decline, Stripe::CardError will be caught
      body = e.json_body
      err  = body[:error]
      Rails.logger.error "[STRIPE_PAYMENT_ERROR] Sweetch id: #{sweetch.id}. #{e}"
      return { error: err }

    rescue Stripe::InvalidRequestError => e
      # Invalid parameters were supplied to Stripe's API
      body = e.json_body
      err  = body[:error]
      Rails.logger.error "[STRIPE_PAYMENT_ERROR] Sweetch id: #{sweetch.id}. #{e}"
      return { error: err }

    rescue Stripe::AuthenticationError => e
      # Authentication with Stripe's API failed
      # (maybe you changed API keys recently)
      body = e.json_body
      err  = body[:error]
      Rails.logger.error "[STRIPE_PAYMENT_ERROR] Sweetch id: #{sweetch.id}. #{e}"
      return { error: err }

    rescue Stripe::APIConnectionError => e
      # Network communication with Stripe failed
      body = e.json_body
      err  = body[:error]
      Rails.logger.error "[STRIPE_PAYMENT_ERROR] Sweetch id: #{sweetch.id}. #{e}"
      return { error: err }

    rescue Stripe::StripeError => e
      # Display a very generic error to the user, and maybe send
      # yourself an email
      body = e.json_body
      err  = body[:error]
      Rails.logger.error "[STRIPE_PAYMENT_ERROR] Sweetch id: #{sweetch.id}. #{e}"
      return { error: err }

    rescue => e
      # Something else happened, completely unrelated to Stripe
      body = e.json_body
      err  = body[:error]
      Rails.logger.error "[STRIPE_PAYMENT_ERROR] Sweetch id: #{sweetch.id}. #{e}"
      return { error: err }
    end
  end

  def self.refund_transaction(user, sweetch)
    charge_token = sweetch.charge_token

    if !charge_token
      { status: true, amount_refunded: 0 }
    else
      begin
        charge = Stripe::Charge.retrieve(sweetch.charge_token)
        response = charge.refund
        return { status: charge.paid, amount_refunded: response.amount.to_i }
      rescue => e
        # Something else happened, completely unrelated to Stripe
        body = e.json_body
        err  = body[:error]
        Rails.logger.error "[STRIPE_REFUND_ERROR] Sweetch id: #{sweetch.id}. #{e}"
        return { error: err }
      end
    end
  end
end
