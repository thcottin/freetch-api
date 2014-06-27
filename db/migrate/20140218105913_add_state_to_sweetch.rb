class AddStateToSweetch < ActiveRecord::Migration
  def change
    add_column :sweetches, :state, :string
  end
end
