class Sweetch < ActiveRecord::Base

  has_many :feedback_associations
  has_many :feedbacks, through: :feedback_associations
	belongs_to :parker, class_name: "User", foreign_key: :parker_id
	belongs_to :leaver, class_name: "User", foreign_key: :leaver_id

  attr_accessor :eta, :matched_with

	# A notification is scheduled 5 minutes after sweetch creation informing
	# the user that no match is found
	after_create :schedule_not_found_notification

	def as_resource(options = {})
		result = {
			id: self.id,
			state: self.state,
			lat: self.leaver_lat,
			lng: self.leaver_lng,
      leaver_lat: self.leaver_lat,
      leaver_lng: self.leaver_lng,
      parker_lat: self.parker_lat,
      parker_lng: self.parker_lng,
			created_at: self.created_at,
			updated_at: self.updated_at
		}
		result[:parker_id] = self.parker_id if self.parker_id

    if self.in_progress?
      result[:eta] = self.eta
      result[:leaver_facebook_id] = self.leaver.facebook_id
      result[:leaver_ph] = self.leaver.phone
      result[:leaver_first_name] = self.leaver.first_name
      result[:parker_facebook_id] = self.parker.facebook_id
      result[:parker_first_name] = self.parker.first_name
      result[:parker_ph] = self.parker.phone
    end
		result
	end

  # Sweetch State Machine
  # ----------------------------
  # Reflects the status of the Sweetch during its life, from being requested by a leaver
  # claimed by another driver, in progress and validated
  state_machine :state, :initial => :pending do

    # Actions triggered by the state transitions
    # Notify leaver with parker info
    after_transition :pending => :in_progress, :do => [:delete_scheduled_push, :publish_match, :track_sweetch_in_progress]

    # Notify parker that Sweetch has been validated
    after_transition :in_progress => :validated, :do => [:publish_validation, :charge_and_update_credits, :track_sweetch_validated]

    after_transition :in_progress => :failed, :do => [:publish_fail, :track_sweetch_failed, :alert_sweetch_failed]

		after_transition :pending => :cancelled, :do => [:delete_scheduled_push, :track_sweetch_cancelled]

		after_transition :validated => :contested, :do => [:refund_and_update_credits, :track_sweetch_contested]


    # Events
    event :start do
      transition :pending => :in_progress
    end

    event :validate do
      # API received a validation from leaver
      transition :in_progress => :validated
    end

    event :fail do
      # API received a failed request from leaver or parker
      transition [:pending, :in_progress] => :failed
    end

    event :cancel do
      # API received a cancel request from leaver
      transition :pending => :cancelled
    end

    event :contest do
      # API received support request after leaver has validated
      transition :validated => :contested
    end

    # States
    state :pending do
      # Initial state, sweetch doesn't have an associated parker
    end

    state :in_progress do
      # Parker and leaver are matched, sweetch is happening
    end

    state :cancelled do
      # Sweetch is cancelled before finding a match
    end

    state :failed do
      # Sweetch has failed due to leaver or parker
    end

    state :validated do
      # Sweetch has been validated by leaver
    end

    state :contested do
      # Sweetch has been validated by leaver but argued by parker
    end
  end

	# These methods call Urban Airship and trigger/cancel notifications
  def publish_match
		# then trigger match found
    if self.matched_with == self.parker
      NotificationHelper.publish_match_parker(self)
    elsif self.matched_with == self.leaver
      NotificationHelper.publish_match_leaver(self)
    end
  end

  def publish_validation
    NotificationHelper.publish_validation(self)
  end

  def publish_fail
    NotificationHelper.publish_fail(self)
  end

	def schedule_not_found_notification
		NotificationHelper.schedule_publish_not_found(self.requested_by, self)
	end

	def delete_scheduled_push
		NotificationHelper.delete_scheduled_push(self)
	end

  def initial_location
    if self.leaver_lat && self.leaver_lng
      Distance.new(lat: self.leaver_lat, lng: self.leaver_lng)
    elsif self.parker_lat && self.parker_lng
      Distance.new(lat: self.parker_lat, lng: self.parker_lng)
    end
  end

  def get_eta
    parker_location = Distance.new(lat: self.parker_lat, lng: self.parker_lng)
    leaver_location = Distance.new(lat: self.leaver_lat, lng: self.leaver_lng)

    if parker_location.valid? && leaver_location.valid?
      self.eta = Distance.eta(parker_location, leaver_location)
    end
  end

  ## CREDITS UPDATE
  ## Using Stripe for transactions

	def charge_and_update_credits
		response = PaymentHelper.create_transaction(self.parker, self)
		self.leaver.add_credits
		unless response[:error]
			self.parker.charge_credits(response[:amount_charged] / 100)
		end
	end

	def refund_and_update_credits
		response = PaymentHelper.refund_transaction(self.parker, self)
		unless response[:error]
			self.parker.refund_credits(response[:amount_refunded] / 100)
		end
	end

  def ready_to_start
    self.parker_lat && self.parker_lng && self.leaver_lat && self.leaver_lng && self.parker_id && self.leaver_id
  end

  def drivers
    [self.leaver, self.parker]
  end

  def requested_by
    user = self.leaver
    user ||= self.parker
    user
  end
end
