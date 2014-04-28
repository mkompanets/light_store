module LightStore
  module ClassMethods
    def datastore
      LightStore.configuration.redis
    end

    def marshal(h)
      Marshal.dump(h)
    end

    def unmarshal(h)
      Marshal.load(h)
    end

    def time_to_integer(t)
      case t
      when Integer, String
        t = Time.new(t)
      when Date, Time
        # do nothing
      else
        raise ArgumentError, "#{t.inspect}: #{t.class.name} should be string,integer,date or time"
      end
      Time.parse(t.to_s).to_i
    end

    def add_data(data)
      datastore.pipelined do
        data.each do |h|
          self.row = h
          self.persist_row
        end
      end
    end

    def persist_row
      datastore.set(row_key, marshal(self.row))
      datastore.set(row_reference_key, row_key)
      _primary_range_key = primary_range_key(self.primary_key)
      datastore.zadd(_primary_range_key, secondary_key, row_reference_key)
      datastore.zadd(range_key, secondary_key, row_reference_key)
    end

    def get_data(options = {})
      reference_keys = []
      if options.has_key?(:primary_key)
        # With primary key.
        if options.has_key?(:date_range)
          # With date range.
          reference_keys = get_data_by_range(options[:primary_key], *options[:date_range])
        else
          # date_range was not passed in, getting data for the key.
          reference_keys = get_all_reference_keys(options[:primary_key])
        end
      else
        # Without primary key.
        if options.has_key?(:date_range)
          reference_keys = get_data_by_range(nil, *options[:date_range])
        else
          # date_range was not passed in, getting all data.
          reference_keys = get_all_reference_keys()
        end
      end
      return [] if reference_keys.empty?
      get_data_by_reference_keys(reference_keys)
    end

    def get_data_by_reference_keys(reference_keys)
      row_keys = datastore.mget(reference_keys)
      marshaled_data = datastore.mget(row_keys)
      marshaled_data.collect{ |d| unmarshal(d) }
    end

    def get_all_reference_keys(primary_key = nil)
      key_substring = "#{base_name}:key:#{primary_key}*"
      datastore.keys(key_substring)
    end

    def get_data_by_range(_primary_key = nil, start_date, stop_date)
      min = time_to_integer(start_date)
      max = time_to_integer(stop_date)
      if _primary_key.nil?
        # range_key
        return datastore.zrangebyscore(range_key, min, max)
      else
        # primary_range_key
        _primary_range_key = primary_range_key(_primary_key)
        return datastore.zrangebyscore(_primary_range_key, min, max)
      end
    end

    def clear_all
      all_keys = datastore.keys("#{base_name}*")
      clear(all_keys)
    end

    def clear(keys)
      deleted_count = datastore.del(keys) unless keys.empty?
    end
  end
end