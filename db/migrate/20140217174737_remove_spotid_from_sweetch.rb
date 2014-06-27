class RemoveSpotidFromSweetch < ActiveRecord::Migration
  def change
  	remove_column :sweetches, :spot_id
  end
end
