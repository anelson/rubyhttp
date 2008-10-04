require File.dirname(__FILE__) + "/../http_impl.rb"

begin
  require File.dirname(__FILE__) + '/rfuzz/pushbackiond.rb'
  require File.dirname(__FILE__) + '/rfuzz/streamclient.rb'

  rfuzz_available = true
  puts "rfuzz tests are available"
rescue LoadError
  rfuzz_available = false
  puts "rfuzz tests are not available (#{$!})"
end

class RfuzzHttpImpl < HttpImpl
  def initialize(rfuzz_available)
    super("rfuzz", rfuzz_available)
  end

  protected

  def get_impl(uri, &block)
    client = StreamingHttpClient.new(uri.host, uri.port)
    client.sendrecv_streaming_request("GET", uri.path, {}) do |chunk|
      block.call chunk
    end
  end
end

RfuzzHttpImpl.new(rfuzz_available)
