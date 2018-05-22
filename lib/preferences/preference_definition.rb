module Preferences
  # Represents the definition of a preference for a particular model
  class PreferenceDefinition
    # The data type for the content stored in this preference type
    attr_reader :type, :name

    def initialize(name, *args) #:nodoc:
      options = args.extract_options!
      options.assert_valid_keys(:default, :group_defaults)

      @name = name
      @type = args.first ? args.first.to_sym : :boolean

      cast_type = ActiveRecord::Type.lookup(@type)
      @from_database = ActiveRecord::Attribute.from_database(name, options[:default], cast_type)
      @from_user = ActiveRecord::Attribute.from_user(name, options[:default], cast_type)

      @group_defaults = (options[:group_defaults] || {}).inject({}) do |defaults, (group, default)|
        defaults[group.is_a?(Symbol) ? group.to_s : group] = type_cast(default)
        defaults
      end
    end

    # The default value to use for the preference in case none have been
    # previously defined
    def default_value(group = nil)
      @group_defaults.include?(group) ? @group_defaults[group] : @from_database.value
    end

    # Typecasts the value based on the type of preference that was defined.
    # This uses ActiveRecord's typecast functionality so the same rules for
    # typecasting a model's columns apply here.
    def type_cast(value)
      @from_database.type_cast(value)
    end

    def type_cast_for_database(value)
      @from_user.type_cast(value)
    end

    # Typecasts the value to true/false depending on the type of preference
    def query(value)
      if !(value = type_cast(value))
        false
      elsif value.is_a? Numeric
        !value.zero?
      else
        !value.blank?
      end
    end
  end
end
