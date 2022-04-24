require 'faraday'
require 'ozon-logistics/ozon_logistics_error'
require 'ozon-logistics/ozon_error'
require 'ozon-logistics/request'
require 'ozon-logistics/api_request'
require 'ozon-logistics/response'
require 'ozon-logistics/version'

module OzonLogistics
  class << self
    def generate_access_token(client_id=OzonLogistics.client_id, client_secret=OzonLogistics.client_secret, grant_type=OzonLogistics.grant_type)
      response = Faraday.post(OzonLogistics.url_token, "grant_type=#{grant_type}&client_id=#{client_id}&client_secret=#{client_secret}")
      JSON.parse(response.body)
    end

    def setup
      yield self
    end

    def register(name, value, type = nil)
      cattr_accessor "#{name}_setting".to_sym

      add_reader(name)
      add_writer(name, type)
      send "#{name}=", value
    end

    def add_reader(name)
      define_singleton_method(name) do |*args|
        send("#{name}_setting").value(*args)
      end
    end

    def add_writer(name, type)
      define_singleton_method("#{name}=") do |value|
        send("#{name}_setting=", DynamicSetting.build(value, type))
      end
    end
  end

  class DynamicSetting
    def self.build(setting, type)
      (type ? klass(type) : self).new(setting)
    end

    def self.klass(type)
      klass = "#{type.to_s.camelcase}Setting"
      raise ArgumentError, "Unknown type: #{type}" unless OzonLogistics.const_defined?(klass)
      OzonLogistics.const_get(klass)
    end

    def initialize(setting)
      @setting = setting
    end

    def value(*_args)
      @setting
    end
  end
end
