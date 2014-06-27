class FeedbackAssociation < ActiveRecord::Base
  belongs_to :sweetch
  belongs_to :feedback
  belongs_to :user

  validates :user_id, presence: true
  validates :sweetch_id, presence: true
  validates :feedback_id, presence: true

end