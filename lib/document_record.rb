module DocumentRecord
  class Document < Hash
    def changed
      @changed ||= []
    end

    def []= key, val
      super key.to_s, val
      changed.push key.to_s
    end
    def has_changed? 
      ! changed.empty?
    end
  end

  module Base 
    extend ActiveSupport::Concern

    def document_field name
      raise unless column_names.include? name.to_s
      @@_document_field_name = name
      @@_index_fields ||= []

      class_eval do
        alias_method :regular_assign_attributes, :assign_attributes
        alias_method :regular_method_missing, :method_missing

        def read_serialized_hash_attribute field_name
          raw = read_attribute field_name
          raw && JSON.load( raw ) || {}
        end
        
        def write_serialized_hash_attribute field_name, hash
          write_attribute field_name, JSON.dump(hash)
        end

        def document &block
          if block
            _document = Document[read_serialized_hash_attribute(@@_document_field_name)]
            yield _document
            if _document.has_changed?
              _document.changed.each do |field| 
                write_attribute field, _document[field] if is_indexed? field
              end
              write_serialized_hash_attribute @@_document_field_name, _document 
            end
          else
            read_serialized_hash_attribute(@@_document_field_name).freeze
          end
        end

        def assign_attributes new_attributes, options
          new_attributes.each do | key, value |
            document do |d|
              d[key] = value
            end
          end
        end

        def method_missing method, *args
          if method =~ /(.*)=$/ 
            document do |d|
              d[$1] = args.shift
            end
          else
            document[method.to_s]
          end
        end

        def is_indexed? attr
          @@_index_fields.include? attr.to_s
        end
      end  
    end

    def index_fields *args
      @@_index_fields = args.collect do |name| 
        raise unless column_names.include? name.to_s 
        name.to_s
      end
    end
  end
end

ActiveRecord::Base.send :extend, DocumentRecord::Base
