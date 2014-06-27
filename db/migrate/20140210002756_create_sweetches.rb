class CreateSweetches < ActiveRecord::Migration
  def change
    create_table :sweetches do |t|
      t.string :spot_id
      t.string :user_id
      t.string :driver_id

      t.timestamps
    end
  end
end
