class AddDriverToFeedback < ActiveRecord::Migration
  def change
    add_column :feedbacks, :driver, :string
  end
end
