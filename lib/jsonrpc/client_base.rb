require 'multi_json'
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

    def services
      @api ||= @helper.connection.get @url
      @api['services']
    end
  end
end
