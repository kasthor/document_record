class SampleModel < ActiveRecord::Base
  document_field :object, schema_fields: [ :created_at, :updated_at ]

  def json_method
    "json_method_content"
  end
end
