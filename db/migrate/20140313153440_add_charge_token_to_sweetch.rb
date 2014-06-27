class AddChargeTokenToSweetch < ActiveRecord::Migration
  def change
    add_column :sweetches, :charge_token, :string
  end
end
