class CreateConclusions < ActiveRecord::Migration[7.0]
  def change
    create_table :conclusions do |t|
      t.string :conclusion
      t.string :context, array: true, default: []

      t.timestamps
    end
  end
end
