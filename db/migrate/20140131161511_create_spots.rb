class CreateSpots < ActiveRecord::Migration
  def change
    create_table :spots do |t|
      t.float :lat
      t.float :lng
      t.string :address

      t.timestamps
    end

    add_index :spots, [:lat, :lng]
  end
end
