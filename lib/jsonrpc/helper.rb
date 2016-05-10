module JSONRPC
  class Helper
    def initialize(opts)
      @options = opts
      @options[:content_type] ||= 'application/json'
      @connection = @options.delete(:connection)
    end

    def options(additional_options = nil)
      if additional_options
        @options.merge(additional_options)
      else
        @options
      end
    end

    def connection
      @connection || ::Faraday.new do |connection|
        connection.response :logger, ::JSONRPC.logger
        connection.adapter ::Faraday.default_adapter
      end
    end
  end
end
