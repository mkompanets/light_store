module LightStore
  class Configuration
    def initialize
      self.redis = nil
    end

    def redis
      @redis
    end

    def redis=(r)
      @redis = r
    end
  end
end