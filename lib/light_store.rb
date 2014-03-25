require "light_store/version"
require "light_store/configuration"
require "light_store/class_methods"

module LightStore

  def self.configuration
    @configuration ||=  Configuration.new
  end

  def self.configure
    yield(configuration) if block_given?
  end

  class << self
    def included(base)
      base.extend ClassMethods
    end
  end

  class Data
    include LightStore

    def namespace
      self.class.namespace
    end

    def primary_key
      self.class.primary_key
    end

    def secondary_key
      self.class.secondary_key
    end
  end
end