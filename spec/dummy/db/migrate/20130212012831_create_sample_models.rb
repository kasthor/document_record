class CreateSampleModels < ActiveRecord::Migration
  def change
    create_table :sample_models do |t|
      t.string :object
      t.string :indexed_field
      t.integer :indexed_integer

      t.timestamps
    end
  end
end
