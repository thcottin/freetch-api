class ChangeFacebookIdTypeInUsers < ActiveRecord::Migration
  def change
    change_column :users, :facebook_id, :integer, :limit => 8
  end
end
