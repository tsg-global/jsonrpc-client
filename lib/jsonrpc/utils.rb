module JSONRPC
  JSON_RPC_VERSION = '2.0'

  module Utils
    def self.generate_id
      rand(10**12)
    end
  end
end
