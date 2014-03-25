module LightStore
  module ClassMethods
    def datastore
      LightStore.configuration.redis
    end

    def set_namespace(x)
      @namespace = x
    end

    def namespace
      @namespace ||= 'light_store'
    end

    def set_prefix(x)
      @prefix = x
    end

    def prefix
      @prefix ||= self.name
    end

    def set_primary_key(x)
      @primary_key = x
    end

    def primary_key
      @primary_key ||= :id
    end

    def set_secondary_key(x)
      @secondary_key = x
    end

    def secondary_key
      raise ArgumentError, 'secondary_key must be set' unless @secondary_key
      @secondary_key
    end

    def set_sortable_field(field_name, field_type = :integer)
      allowed_field_types = [:integer, :float, :datetime]
      raise ArgumentError, 'field_type must be [:integer, :float, :datetime]' unless allowed_field_types.include?(field_type)
      h = {field_name: field_name, field_type: field_type}
      @sortable_fields = self.sortable_fields
      @sortable_fields.push(h) unless @sortable_fields.include?(h)
    end

    def sortable_fields
      @sortable_fields ||= []
    end

    def marshal(h)
      Marshal.dump(h)
    end

    def unmarshal(h)
      Marshal.load(h)
    end

    def base_key
      "#{namespace}:#{prefix}"
    end

    def base_data_key
      "#{base_key}:data"
    end

    def base_member_ids_key
      "#{base_key}:member_ids"
    end

    def base_sorted_member_ids_key
      "#{base_key}:sorted_member_ids"
    end

    def get_primary_id(h)
      raise ArgumentError, 'primary_id must be set' unless h[primary_key]
      h[primary_key]
    end

    def get_secondary_id(h)
      raise ArgumentError, 'secondary_key must be set' unless h[secondary_key]
      h[secondary_key]
    end

    def get_data_row_key(h)
      "#{base_data_key}:#{get_primary_id(h)}:#{get_secondary_id(h)}"
    end

    def get_member_id_key(h)
      "#{base_member_ids_key}:#{get_primary_id(h)}"
    end

    def get_sorted_member_id_key(_primary_id, _sortable_field)
      "#{base_sorted_member_ids_key}:#{_primary_id}:#{_sortable_field}"
    end

    def get_score(value, sortable_field_type)
      raise ArgumentError, "value for #{sortable_field_type} must be set" unless value
      case sortable_field_type
      when :integer
        value.to_i
      when :float
        value.to_f
      when :datetime
        if value.is_a? Time
          value.to_i
        else
          Time.parse(value).to_i
        end
      else
        raise ArgumentError, "score value for #{sortable_field_type} must be in proper format"
      end
    end

    def add_member_id(h)
      member_id_key = get_member_id_key(h)
      data_row_key = get_data_row_key(h)
      datastore.sadd(member_id_key, data_row_key)
    end

    def add_sorted_member_ids(h)
      sortable_fields.each do |s|
        field_name = s[:field_name]
        field_type = s[:field_type]
        add_sorted_member_id(h, field_name, field_type)
      end
    end

    def add_sorted_member_id(h, field_name, field_type)
      primary_id = get_primary_id(h)
      sorted_member_id = get_sorted_member_id_key(primary_id, field_name)
      data_row_key = get_data_row_key(h)
      value = h[field_name]
      score = get_score(value, field_type)
      datastore.zadd(sorted_member_id, score, data_row_key)
    end

    def get_member_ids(_primary_key = nil)
      key = _primary_key ? "#{base_member_ids_key}:#{_primary_key}" : base_member_ids_key
      member_keys = datastore.keys("#{key}*")
      member_keys.collect{ |k| datastore.smembers(k) }.flatten
    end

    def add_data(data)
      added_records_count = 0
      data.each do |h|
        data_row_key = get_data_row_key(h)
        marshaled_h = marshal(h)
        new_member_check = add_member_id(h)
        if new_member_check
          datastore.set(data_row_key, marshaled_h)
          add_sorted_member_ids(h)
        else
          old_value = datastore.getset(data_row_key, marshaled_h)
          if old_value != marshaled_h
            add_sorted_member_ids(h)
          end
        end
        added_records_count += 1 if new_member_check
      end
      #plural_records = added_records_count == 1 ? "record" : "records"
      return added_records_count
    end

    def get_data(_primary_key = nil)
      data_keys = _primary_key ? get_member_ids(_primary_key) : get_member_ids()
      return [] if data_keys.empty?
      marshaled_data = datastore.mget(data_keys)
      unmarshaled_data = marshaled_data.collect{ |d| unmarshal(d) }
    end

    def get_sorted_data(_primary_key, _sortable_field, min, max, options = {})
      grouped_sortable_fields = sortable_fields.group_by { |f| f[:field_name] }
      raise ArgumentError, "No sortable fields declared" if grouped_sortable_fields.empty?
      raise ArgumentError, "sortable field '#{_sortable_field}' not declared" unless grouped_sortable_fields.has_key?(_sortable_field)
      field_type = grouped_sortable_fields[_sortable_field].first[:field_type]
      min = get_score(min, field_type) unless min == '-inf'
      max = get_score(max, field_type) unless max == '+inf'
      sorted_member_id = get_sorted_member_id_key(_primary_key, _sortable_field)

      data_keys = datastore.zrangebyscore(sorted_member_id, min, max, options)
      marshaled_data = datastore.mget(data_keys)
      unmarshaled_data = marshaled_data.collect{ |d| unmarshal(d) }
    end

    def clear_all_data
      data_keys = datastore.keys("#{base_member_ids_key}*")
      data_keys = data_keys.concat(datastore.keys("#{base_sorted_member_ids_key}*"))
      data_keys = data_keys.concat(datastore.keys("#{base_data_key}*"))
      clear(data_keys)
    end

    def clear_all
      all_keys = datastore.keys("#{base_key}*")
      clear(all_keys)
    end

    # make private.
    def clear(keys)
      deleted_count = datastore.del(keys) unless keys.empty?
    end

  end
end