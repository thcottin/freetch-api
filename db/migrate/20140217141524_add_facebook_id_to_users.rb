class AddFacebookIdToUsers < ActiveRecord::Migration
  def change
    add_column :users, :facebook_id, :integer
    add_index :users, :facebook_id
  end
end
