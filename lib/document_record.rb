require 'document_hash'

module DocumentRecord
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
        alias_method :regular_save, :save

        def read_serialized_hash_attribute field_name
          raw = read_attribute field_name
          raw && Serializer.load( raw ) || {}
        end
        
        def write_serialized_hash_attribute field_name, hash
          write_attribute field_name, Serializer.dump(hash)
        end

        def document
          @document ||= ::DocumentHash::Core[read_serialized_hash_attribute(@@_document_field_name)].tap do |d|
            d.before_change do |path, value|
              key = path.join "_"
              
              value = case self.class.columns_hash[key].type
                when :integer then value.to_i
                else value
              end if self.class.columns_hash[key]

              value
            end
            d.after_change do |path, value|
              key = path.join "_"
              write_attribute key, value if self.class.columns_hash[key]
            end
          end
        end

        def save *arguments
          save_document
          regular_save *arguments
        end

        def save_document
          write_serialized_hash_attribute @@_document_field_name, document.to_hash
        end

        def assign_attributes new_attributes, options
          new_attributes.each do | key, value |
            self.send "#{key}=".to_sym, value
          end 
        end

        def method_missing method, *args
          if method =~ /(.*)=$/ 
            document[$1] = args.shift
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
          def #{column}
            document["#{column}"] || read_attribute("#{column}")
          end
          def #{column}= value
            document["#{column}"] = value
          end
        METHOD
      end
    end
  end
end

ActiveRecord::Base.send :extend, DocumentRecord::Base
