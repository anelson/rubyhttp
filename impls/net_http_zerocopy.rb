require File.dirname(__FILE__) + "/../http_impl.rb"
require File.dirname(__FILE__) + "/net_http_zerocopy/http.rb"

class CustomNetHttpZeroCopyImpl < HttpImpl
  def initialize()
    super('net/http with 16k buf, zero-copy reads, select()',true)
  end

  protected

  def get_impl(uri, &block)
    Net::CustomHTTPZeroCopy.start(uri.host, uri.port) do |http|
      http.request_get(uri.path) do |response|
        response.read_body do |body|
          block.call body
        end
      end
    end
  end
end

CustomNetHttpZeroCopyImpl.new()

