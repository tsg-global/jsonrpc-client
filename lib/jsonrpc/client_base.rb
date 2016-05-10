require 'multi_json'
require 'faraday'
require 'uri'
require 'jsonrpc/helper'

module JSONRPC
  # @abstract
  class ClientBase < BasicObject
    def initialize(url, **opts)
      @url = ::URI.parse(url).to_s
      @options = opts
      reload
    end

    def reload
      @helper = ::JSONRPC::Helper.new(@options)
      @api = nil
    end

    def to_s
      inspect
    end

    def inspect
      "#<#{self.class.name}:0x00%08x>" % (__id__ * 2)
    end

    def class
      (class << self; self end).superclass
    end

    def services
      @api ||= @helper.connection.get
      @api['services']
    end

  private
    def raise(*args)
      ::Kernel.raise(*args)
    end
  end
end
