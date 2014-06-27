class AddSweetchidToSpots < ActiveRecord::Migration
  def change
  	add_column :spots, :sweetch_id, :integer
  end
end
