class AddUserIdToSpots < ActiveRecord::Migration
  def change
    add_column :spots, :user_id, :integer
  end
end
