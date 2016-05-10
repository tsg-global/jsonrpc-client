require 'spec_helper'

module JSONRPC
  describe Client do
    BOILERPLATE = {'jsonrpc' => '2.0', 'id' => 1}

    let(:connection) { double('connection') }

    before(:each) do
      @resp_mock = double('http_response')
      allow(JSONRPC::Utils).to receive(:generate_id).and_return(1)
    end

    after(:each) do
    end

    describe "#call" do
      let(:expected) do
        MultiJson.encode(
          'jsonrpc' => '2.0',
          'method'  => 'foo',
          'params'  => [1,2,3],
          'id'      => 1
        )
      end

      before(:each) do
        response = MultiJson.encode(BOILERPLATE.merge({'result' => 42}))
        expect(@resp_mock).to receive(:body).at_least(:once).and_return(response)
        @client = Client.new(SPEC_URL, connection: connection)
      end

      context "when using an array of args" do
        it "sends a request with the correct method and args" do
          expect(connection).to receive(:post).with(SPEC_URL, expected, content_type: 'application/json').and_return(@resp_mock)
          expect(@client.invoke('foo', [1, 2, 3])).to eq(42)
        end
      end

      context "with headers" do
        it "adds additional headers" do
          expect(connection).to receive(:post).with(SPEC_URL, expected, content_type: 'application/json', "X-FOO" => "BAR").and_return(@resp_mock)
          expect(@client.invoke('foo', [1, 2, 3], "X-FOO" => "BAR")).to eq(42)
        end
      end
    end

    describe "sending a single request" do
      context "when using positional parameters" do
        before(:each) do
          @expected = MultiJson.encode({
            'jsonrpc' => '2.0',
            'method'  => 'foo',
            'params'  => [1,2,3],
            'id'      => 1
          })
        end

        it "sends a valid JSON-RPC request and returns the result" do
          response = MultiJson.encode(BOILERPLATE.merge({'result' => 42}))
          expect(connection).to receive(:post).with(SPEC_URL, @expected, content_type: 'application/json').and_return(@resp_mock)
          expect(@resp_mock).to receive(:body).at_least(:once).and_return(response)
          client = Client.new(SPEC_URL, connection: connection)
          expect(client.call(:foo, 1,2,3)).to eq(42)
        end

        it "sends a valid JSON-RPC request with custom options" do
          response = MultiJson.encode(BOILERPLATE.merge({'result' => 42}))
          expect(connection).to receive(:post).with(SPEC_URL, @expected, content_type: 'application/json', timeout: 10000).and_return(@resp_mock)
          expect(@resp_mock).to receive(:body).at_least(:once).and_return(response)
          client = Client.new(SPEC_URL, timeout: 10000, connection: connection)
          expect(client.call(:foo, 1,2,3)).to eq(42)
        end

        it "sends a valid JSON-RPC request with custom content_type" do
          response = MultiJson.encode(BOILERPLATE.merge({'result' => 42}))
          expect(connection).to receive(:post).with(SPEC_URL, @expected, content_type: 'application/json-rpc', timeout: 10000).and_return(@resp_mock)
          expect(@resp_mock).to receive(:body).at_least(:once).and_return(response)
          client = Client.new(SPEC_URL, timeout: 10000, content_type: 'application/json-rpc', connection: connection)
          expect(client.call(:foo, 1,2,3)).to eq(42)
        end
      end
    end

    context "sending a batch request" do
      it "sends a valid JSON-RPC batch request and puts the results in the response objects" do
        batch = MultiJson.encode([
          { "jsonrpc" => "2.0", "method" => "sum", "id" => "1", "params" => [1,2,4] },
          { "jsonrpc" => "2.0", "method" => "subtract", "id" => "2", "params" => [42,23] },
          { "jsonrpc" => "2.0", "method" => "foo_get", "id" => "5", "params" => [{"name" => "myself"}] },
          { "jsonrpc" => "2.0", "method" => "get_data", "id" => "9" }
        ])

        response = MultiJson.encode([
          { "jsonrpc" => "2.0", "result" => 7, "id" => "1" },
          { "jsonrpc" => "2.0", "result" => 19, "id" => "2" },
          { "jsonrpc" => "2.0", "error" => {"code" => -32601, "message" => "Method not found."}, "id" => "5" },
          { "jsonrpc" => "2.0", "result" => ["hello", 5], "id" => "9" }
        ])

        allow(JSONRPC::Utils).to receive(:generate_id).and_return('1', '2', '5', '9')
        expect(connection).to receive(:post).with(SPEC_URL, batch, content_type: 'application/json').and_return(@resp_mock)
        expect(@resp_mock).to receive(:body).at_least(:once).and_return(response)

        sum = subtract = foo = data = nil
        client = BatchClient.new(SPEC_URL, connection: connection) do |batch|
          sum = batch.call :sum, 1,2,4
          subtract = batch.call :subtract, 42, 23
          foo = batch.call :foo_get, 'name' => 'myself'
          data = batch.call :get_data
        end

        expect(sum).to be_succeeded
        expect(sum).not_to be_is_error
        expect(sum.result).to eq(7)

        expect(subtract.result).to eq(19)

        expect(foo).to be_is_error
        expect(foo).not_to be_succeeded
        expect(foo.error).to have_key('code')
        expect(foo.error['code']).to eq(-32601)

        expect(data.result).to eq(['hello', 5])

        expect { client.sum(1, 2) }.to raise_error(NoMethodError)
      end
    end
  end
end
