class CreateQuestions < ActiveRecord::Migration[7.0]
  def change
    create_table :questions do |t|
      t.string :statement
      t.string :question_id

      t.timestamps
    end
  end
end
