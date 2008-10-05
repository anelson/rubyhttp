require File.dirname(__FILE__) + "/../http_impl.rb"
require File.dirname(__FILE__) + "/187_net_http_notimeout/http.rb"

class CustomNetHttpNoTimeoutImpl < HttpImpl
  def initialize()
    super('1.8.7 net/http with no timeout', false) #true)
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

