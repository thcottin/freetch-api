class ChangeColumnSweetch < ActiveRecord::Migration
  def change
    rename_column :sweetches, :user_id, :leaver_id
    rename_column :sweetches, :driver_id, :parker_id
  end
end
