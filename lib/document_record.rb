module DocumentRecord
  module Base 
    extend ActiveSupport::Concern

    def document_field name
      raise unless column_names.include? name.to_s
      @@_document_field_name = name
      @@_index_fields ||= []

      serialize name, JSON

      class_eval do
        alias_method :regular_assign_attributes, :assign_attributes
        alias_method :regular_method_missing, :method_missing

        def document
          read_attribute @@_document_field_name or {}
        end

        def document= arg
          write_attribute @@_document_field_name, arg
        end

        def assign_attributes new_attributes, options
          new_attributes.each do | key, value |
            __send__ "#{key}=".to_sym, value
          end
        end

        def method_missing method, *args
          _document = send :document
          if method.to_s =~ /(.*)=$/
            _attr = $1.to_sym
            _val = args.shift
            _document[_attr] = _val
            write_attribute _attr, _val if is_indexed? _attr
            send :document=, _document
          else
            _document[method]
          end
        end

        def is_indexed? attr
          @@_index_fields.include? attr
        end
      end  
    end

    def index_fields *args
      @@_index_fields = args.collect do |name| 
        raise unless column_names.include? name.to_s 
        name.to_sym
      end
    end
  end
end

ActiveRecord::Base.send :extend, DocumentRecord::Base
