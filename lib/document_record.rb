module DocumentRecord
  class Document < Hash
    def changed
      @changed ||= Set.new
    end

    def []= key, val
      super key.to_s, val
      changed << key.to_s
    end
    def has_changed? 
      ! changed.empty?
    end
  end

  module Serializer
    def self.dump object
      Base64.encode64 Marshal.dump object
    end
    def self.load data
      Marshal.load Base64.decode64 data rescue nil
    end
  end

  module Base 
    extend ActiveSupport::Concern

    def document_field name
      raise "Field must exist in record in order to become a document field" unless column_names.include? name.to_s
      @@_document_field_name = name
      @@_index_fields ||= []

      class_eval do
        alias_method :regular_assign_attributes, :assign_attributes
        alias_method :regular_method_missing, :method_missing

        def read_serialized_hash_attribute field_name
          raw = read_attribute field_name
          raw && Serializer.load( raw ) || {}
        end
        
        def write_serialized_hash_attribute field_name, hash
          write_attribute field_name, Serializer.dump(hash)
        end

        def document &block
          if block
            _document = Document[read_serialized_hash_attribute(@@_document_field_name)]

            process_indexed_value = lambda do | hash, key, field |
              #TODO: Do proper casting
              hash[key] = case self.class.columns_hash[field].type
                when :integer then hash[key].to_i
                else hash[key]
              end

              write_attribute field, hash[key] 
            end

            yield _document
            if _document.has_changed?
              _document.changed.each do |field| 
                if _document[field].is_a? Hash
                  prefix = "#{field}_"

                  _document[field].each do |key, value|
                    name = "#{prefix}#{key}"

                    process_indexed_value.call _document[field], key, name if is_indexed? name
                  end
                end

                process_indexed_value.call _document, field, field if is_indexed? field
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
          self.class.column_names.include? attr.to_s
        end

        def as_json options = {}
          ( read_serialized_hash_attribute(@@_document_field_name) || {} ).merge(super.reject{ |k, v| k === @@_document_field_name.to_s })
        end
      end  

      column_names.each do |column|
        class_eval <<-METHOD
          def #{column}= value
            document do |d|
              d["#{column}"] = value
            end
          end
        METHOD
      end
    end
  end
end

ActiveRecord::Base.send :extend, DocumentRecord::Base
