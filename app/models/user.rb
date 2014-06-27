class User < ActiveRecord::Base

  attr_accessor :location, :card_token, :register_for_notifications, :mixpanel_id

  has_many :sweetches, foreign_key: :leaver_id
  has_many :feedback_associations
  has_many :feedbacks, through: :feedback_associations
  has_many :locations

	validates :token, presence: true
	validates :first_name,  presence: true, length: { maximum: 50 }
	validates :last_name,  presence: true, length: { maximum: 50 }
	VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
	validates :email, presence: true, format: { with: VALID_EMAIL_REGEX },
                      uniqueness: { case_sensitive: false }
  validates :credits, :numericality => { :greater_than_or_equal_to => 0 }

  # Create stripe customer
  # before_save :track_card_given, if: :card_token_exists?
  before_save :create_stripe_customer, if: :card_token_exists?
  after_create :alert_signup

  # Update device token in Urban Airship if it changes
  # Device token changes when the iOS app changes from development to release
  after_save :register_device, if: :register_for_notifications

  def as_resource(options = {})
    result = {
      id: self.id,
      facebook_id: self.facebook_id,
      first_name: self.first_name,
      last_name: self.last_name,
      email: self.email,
      created_at: self.created_at,
      updated_at: self.updated_at,
      count_sweetch: self.count_sweetch,
      credits: self.credits
    }

    if self.phone
      result[:phone] = self.phone
    end

    if self.customer_token
      result[:is_customer] = true
    else
      result[:is_customer] = false
    end

    if options[:card]
      if self.customer?
        card_details = PaymentHelper.retrieve_customer(self)
        result[:card] = {
          last4: card_details["last4"],
          type: card_details["type"]
        }
      end
    end

    # Tell front end if the user has been created or updated
    result[:created] = true if options[:created]

    result
  end

  def card_token_exists?
    !!self.card_token
  end

  def customer?
    !!self.customer_token
  end

  def create_stripe_customer
    PaymentHelper.create_customer(self)
    Alert.card_given(self)
  end

  def give_credits
    unless Rails.env == "test"
      property = Property.where(key: "initial_credits").first
      self.credits =+ property.value.to_i
    end
  end

  def alert_signup
    return if Rails.env == "staging"
    Alert.signup(self)
  end

  # register the user device token at Urban Airship
  def register_device
    Urbanairship.register_device(self.device_token, :alias => self.email)
  end

  def amount_to_charge
    self.credits >= PaymentHelper::SWEETCH_PRICE ? 0 : (PaymentHelper::SWEETCH_PRICE - self.credits)
  end

  def add_credits
    self.increment!(:credits, 4)
  end

  def charge_credits(amount_to_charge = 0)
    self.increment!(:credits, - (PaymentHelper::SWEETCH_PRICE - amount_to_charge))
  end

  def refund_credits(amount_debited = 0)
    self.increment!(:credits, (PaymentHelper::SWEETCH_PRICE - amount_debited))
  end

  def name
    "#{self.first_name} #{self.last_name}"
  end

end
