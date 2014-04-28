module LightStore
  class Configuration
    def initialize
      self.redis = nil
      self.pipelined = true
    end

    def redis
      @redis
    end

    def redis=(r)
      @redis = r
    end

    def pipelined?
      @pipelined
    end

    def pipelined=(b)
      @pipelined = b
    end
  end
end