class CreateSampleModels < ActiveRecord::Migration
  def change
    create_table :sample_models do |t|
      t.string :object
      t.string :inner_attribute
      t.string :indexed_field
      t.datetime :indexed_date
      t.integer :indexed_integer

      t.timestamps
    end
  end
end
