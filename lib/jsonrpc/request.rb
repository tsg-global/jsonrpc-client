require 'jsonrpc/utils'

module JSONRPC
  class Request
    attr_reader :id
    attr_reader :jsonrpc
    attr_reader :method
    attr_reader :params

    def initialize(method:, params: nil, id: nil)
      @jsonrpc = '2.0'.freeze
      @method = method
      @params = params
      @id ||= ::JSONRPC::Utils.generate_id
    end

    def to_h
      h = {
        'jsonrpc' => @jsonrpc,
        'method'  => @method,
        'id' => @id
      }
      h.merge!('params' => @params) if @params && !params.empty?
      h
    end

    def to_json(*a)
      Oj.dump(self.to_h)
    end
  end
end
