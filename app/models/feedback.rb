class Feedback < ActiveRecord::Base
  has_many :feedback_associations
  has_many :sweetches, through: :feedback_associations
end