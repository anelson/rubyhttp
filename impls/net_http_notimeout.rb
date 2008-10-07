require File.dirname(__FILE__) + "/../http_impl.rb"
require File.dirname(__FILE__) + "/net_http_notimeout/http.rb"

class CustomNetHttpNoTimeoutImpl < HttpImpl
  def initialize()
    super('net/http with 16k buf, no timeout', true)
  end

  protected

  def get_impl(uri, &block)
    Net::CustomHTTPNoTimeout.start(uri.host, uri.port) do |http|
      http.request_get(uri.path) do |response|
        response.read_body do |body|
          block.call body
        end
      end
    end
  end
end

CustomNetHttpNoTimeoutImpl.new()

