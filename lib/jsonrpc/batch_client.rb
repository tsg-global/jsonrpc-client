require 'jsonrpc/client_base'
require 'jsonrpc/error'
require 'jsonrpc/request'
require 'jsonrpc/response'
require 'jsonrpc/utils'

module JSONRPC
  class BatchClient < ClientBase
    attr_reader :batch

    def initialize(url, **options)
      super
      @batch = []
      @alive = true
      yield self
      send_batch
      @alive = false
    end

    def call(sym, *args, &block)
      if @alive
        request = ::JSONRPC::Request.new(method: sym.to_s, params: args)
        push_batch_request(request)
      else
        raise ConnectionDead
      end
    end

  private
    def send_batch_request(batch)
      post_data = ::Oj.dump(batch)

      resp = @helper.connection.post(@url, post_data, @helper.options)
      if resp.nil? || resp.body.nil? || resp.body.empty?
        raise ::JSONRPC::Error::InvalidResponse.new
      end

      resp.body
    end

    def process_batch_response(responses)
      responses.each do |resp|
        saved_response = @batch.find do |(req, res)|
          res.id == resp['id']
        end
        unless saved_response
          raise ::JSONRPC::Error::InvalidResponse
        end
        saved_response[1].populate!(resp)
      end
    end

    def push_batch_request(request)
      response = ::JSONRPC::Response.new(request.id)
      @batch << [request, response]
      response
    end

    def send_batch
      batch = @batch.map(&:first) # get the requests
      response = send_batch_request(batch)

      begin
        responses = ::Oj.load(response, ::JSONRPC.decode_options)
      rescue
        raise ::JSONRPC::Error::InvalidJSON.new(json)
      end

      process_batch_response(responses)
      @batch.clear
    end
  end
end
