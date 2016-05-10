require 'jsonrpc/utils'
require 'jsonrpc/request'
require 'jsonrpc/response'
require 'jsonrpc/error'
require 'jsonrpc/helper'
require 'jsonrpc/loggable'
require 'jsonrpc/client_base'
require 'jsonrpc/version'

module JSONRPC
  extend JSONRPC::Loggable

  @decode_options = {}

  def self.decode_options=(options)
    @decode_options = options
  end

  def self.decode_options
    @decode_options
  end

  class Client < ClientBase
    def method_missing(method, *args, &block)
      invoke(method, args)
    end

    def invoke(method, args, options = nil)
      resp = send_single_request(method.to_s, args, options)

      begin
        data = ::MultiJson.decode(resp, ::JSONRPC.decode_options)
      rescue
        raise ::JSONRPC::Error::InvalidJSON.new(resp)
      end

      process_single_response(data)
    rescue => e
      e.extend(::JSONRPC::Error)
      raise
    end

    private
    def send_single_request(method, args, options)
      post_data = ::MultiJson.encode({
        'jsonrpc' => ::JSONRPC::JSON_RPC_VERSION,
        'method'  => method,
        'params'  => args,
        'id'      => ::JSONRPC::Utils.generate_id
      })
      resp = @helper.connection.post(@url, post_data, @helper.options(options))

      if resp.nil? || resp.body.nil? || resp.body.empty?
        raise ::JSONRPC::Error::InvalidResponse.new
      end

      resp.body
    end

    def process_single_response(data)
      raise ::JSONRPC::Error::InvalidResponse.new unless valid_response?(data)

      if data['error']
        code = data['error']['code']
        msg = data['error']['message']
        raise ::JSONRPC::Error::ServerError.new(code, msg)
      end

      data['result']
    end

    def valid_response?(data)
      return false if !data.is_a?(::Hash)
      return false if data['jsonrpc'] != ::JSONRPC::JSON_RPC_VERSION
      return false if !data.has_key?('id')
      return false if data.has_key?('error') && data.has_key?('result')

      if data.has_key?('error')
        if !data['error'].is_a?(::Hash) || !data['error'].has_key?('code') || !data['error'].has_key?('message')
          return false
        end

        if !data['error']['code'].is_a?(::Fixnum) || !data['error']['message'].is_a?(::String)
          return false
        end
      end

      true
    rescue
      false
    end
  end
end
