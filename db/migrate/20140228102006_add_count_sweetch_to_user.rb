class AddCountSweetchToUser < ActiveRecord::Migration
  def change
    add_column :users, :count_sweetch, :integer
  end
end
