require File.dirname(__FILE__) + "/../http_impl.rb"
require File.dirname(__FILE__) + "/net_http_zerocopy_sysread/http.rb"

class CustomNetHttpZeroCopySysReadImpl < HttpImpl
  def initialize()
    super(__FILE__, 'net/http with 16k buf, zero-copy reads, sysread()', true)
  end

  protected

  def get_impl(uri, &block)
    Net::CustomHTTPZeroCopySysRead.start(uri.host, uri.port) do |http|
      http.request_get(uri.path) do |response|
        response.read_body do |body|
          block.call body
        end
      end
    end
  end
end

CustomNetHttpZeroCopySysReadImpl.new()

