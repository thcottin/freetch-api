class AddCoordinatesToSweetch < ActiveRecord::Migration
  def change
  	add_column :sweetches, :parker_lat, :float
  	add_column :sweetches, :parker_lng, :float
  	add_column :sweetches, :leaver_lat, :float
  	add_column :sweetches, :leaver_lng, :float
  end
end
