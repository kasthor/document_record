class SampleModel < ActiveRecord::Base
  document_field :object
  index_fields :indexed_field
end
