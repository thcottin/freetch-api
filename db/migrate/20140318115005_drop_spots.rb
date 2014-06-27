class DropSpots < ActiveRecord::Migration
  def change
  	drop_table :spots 
  end
end
