class SampleModel < ActiveRecord::Base
  document_field :object

  def json_method
    "json_method_content"
  end
end
