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

    def document_field name, options = {}
      raise "Field must exist in record in order to become a document field" unless column_names.include? name.to_s
      class_eval do
        alias_method :regular_assign_attributes, :assign_attributes
        alias_method :regular_method_missing, :method_missing
        alias_method :regular_save, :save
        self.singleton_class.send :alias_method, :regular_find, :find


        @@_document_field_name = name
        @@_schema_fields = options[:schema_fields] || []
        @@_index_fields ||= []

        @@_select_fields = [ :id ]
        @@_select_fields << @@_document_field_name
        @@_select_fields += @@_schema_fields

        default_scope select: @@_select_fields

        def self.find *args
          options = args.extract_options!
          fields = []
          fields << @@_document_field_name
          fields += @@_schema_fields
          options = {select: fields}.merge options
          args << options

          self.regular_find *args
        end

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

        def save! *arguments
          save(*arguments) || raise(RecordNotSaved)
        end

        def touch!
          self.document.touch!
          save
        end

        def save_document
          write_serialized_hash_attribute @@_document_field_name, document.to_hash
        end

        def assign_attributes new_attributes, options
          new_attributes.each do | key, value |
            assign_key = :"#{key}="
            method_missing assign_key, value
            self.send assign_key, value if self.respond_to? assign_key
          end 
        end

        def method_missing method, *args
          if method =~ /(.*)=$/ 
            write_document $1, args.shift
          else
            read_document method.to_s
          end
        end

        def is_schema_field? attribute
          @@_schema_fields.include? attribute.to_sym
        end

        def read_document attribute
          if is_schema_field? attribute
            read_attribute attribute
          else
            document[attribute] || read_attribute(attribute)
          end
        end

        def write_document attribute, value
          if is_schema_field? attribute
            write_attribute attribute, value
          else
            document[attribute] = value
          end
        end

        def is_indexed? attr
          self.class.column_names.include? attr.to_s
        end

        def as_json options = {}
          included_fields = super.select{ |k, v|
            @@_schema_fields.include?( k.to_sym ) 
          }.stringify_keys!

          document.to_hash( stringify_keys: true ).
            merge( included_fields ).
            merge( method_values(options) )
        end

        def method_values options
          {}.tap do | result | 
            return result unless options[:methods].is_a? Array
            options[:methods].each do | method |
              result[method] = self.__send__(method)
            end
          end
        end


        def _deep_key_values hash = nil, path = []
          hash = document.to_hash unless hash
          result = []

          hash.each do | k, v |
            current = path.dup
            
            current << k
            if v.is_a? Hash
              result += _deep_key_values hash[ k ], current 
            else
              result += [ current.join("_"), v ]
            end
          end
          result
        end

        def deep_key_values
          Hash[*_deep_key_values]
        end

        def deep_keys
          deep_key_values.keys
        end
      end

      column_names.each do |column|
        class_eval <<-METHOD
          def #{column}
            # document["#{column}"] || read_attribute("#{column}")
            read_document "#{ column }"
          end

          def #{column}= value
            # document["#{column}"] = value
            write_document "#{ column }", value
          end
        METHOD
      end
    end
  end
end

ActiveRecord::Base.send :extend, DocumentRecord::Base
