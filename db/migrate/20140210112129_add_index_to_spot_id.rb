class AddIndexToSpotId < ActiveRecord::Migration
  def change
  	add_index :sweetches, :spot_id, unique: true
  end
end
