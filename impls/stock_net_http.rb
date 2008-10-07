require File.dirname(__FILE__) + "/../http_impl.rb"
require 'net/http'

class StockNetHttpImpl < HttpImpl
  def initialize()
    super('net/http', true)
  end

  protected

  def get_impl(uri, &block)
    Net::HTTP.start(uri.host, uri.port) do |http|
      http.request_get(uri.path) do |response|
        response.read_body do |body|
          block.call body
        end
      end
    end
  end
end

StockNetHttpImpl.new()

