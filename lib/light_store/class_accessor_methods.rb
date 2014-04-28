module LightStore
  module ClassAccessorMethods
    def base_name
      "LightStore:#{self.name}"
    end

    def primary_field(x = nil)
      @primary_field = x unless x.nil?
      raise ArgumentError, 'primary_field must be set' unless @primary_field
      @primary_field
    end

    def date_constraint_field(x = nil)
      @date_constraint_field = x if x
      raise ArgumentError, 'date_constraint_field must be set' unless @date_constraint_field
      @date_constraint_field
    end

    def row=(h)
      @row = h
    end

    def row
      @row
    end

    def primary_key
      row[primary_field]
    end

    def secondary_key
      Time.parse(row[date_constraint_field].to_s).to_i
    end

    def row_key
      "#{base_name}:row:#{primary_key}:#{secondary_key}"
    end

    def row_reference_key
      "#{base_name}:key:#{primary_key}:#{secondary_key}"
    end

    def primary_range_key(x)
      "#{base_name}:primary_range:#{x}"
    end

    def range_key
      "#{base_name}:range"
    end
  end
end