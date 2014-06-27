class CreateFeedbacks < ActiveRecord::Migration
  def change
    create_table :feedbacks do |t|
      t.string :message
    end

    create_table :feedback_associations do |t|
      t.integer :sweetch_id
      t.integer :feedback_id
      t.integer :user_id
    end
  end
end
