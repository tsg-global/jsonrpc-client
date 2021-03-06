require 'oj'
require 'faraday'
require 'uri'
require 'jsonrpc/helper'

module JSONRPC
  # @abstract
  class ClientBase
    attr_reader :url
    attr_reader :options

    def initialize(url, **opts)
      @url = ::URI.parse(url).to_s.freeze
      @options = opts
      reload
    end

    def reload
      @helper = ::JSONRPC::Helper.new(@options)
      @api = nil
    end

    def api
      @api ||= begin
        response = @helper.connection.get @url
        Oj.load(response.body)
      end
    end

    def services
      api['services']
    end

    def rpc_methods
      api['methods']
    end
  end
end
