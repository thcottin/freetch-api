class AddSchedulePushIdToSweetch < ActiveRecord::Migration
  def change
    add_column :sweetches, :scheduled_push_id, :string
  end
end
