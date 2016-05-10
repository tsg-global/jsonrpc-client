require 'multi_json'
require 'faraday'
require 'uri'
require 'jsonrpc/helper'

module JSONRPC
  # @abstract
  class ClientBase
    def initialize(url, **opts)
      @url = ::URI.parse(url).to_s
      @options = opts
      reload
    end

    def reload
      @helper = ::JSONRPC::Helper.new(@options)
      @api = nil
    end

    def services
      @api ||= @helper.connection.get
      @api['services']
    end
  end
end
