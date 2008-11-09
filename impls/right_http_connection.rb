require File.dirname(__FILE__) + "/../http_impl.rb"
require 'net/http'

begin
  require 'right_http_connection'

  puts "right_http_connection tests are available"
  warn("WARNING: right_http_connection monkey-patches Net::HTTP.  Stock Net::HTTP performance results will be inaccurate")
  right_available = true
rescue LoadError
  right_available = false
  puts "right_http_connection tests are not available (#{$!})"
end

class RightHttpConnectiontHttpImpl < HttpImpl
  def initialize(right_available)
    super(__FILE__, 'right_http_connection', right_available)
  end

  protected

  def get_impl(uri, &block)
    Net::HTTP.start(uri.host, uri.port) do |http|
      req = Net::HTTP::Get.new(uri.path)
      http.request(req) do |response|
        response.read_body do |body|
          block.call body
        end
      end
    end
  end
end

RightHttpConnectiontHttpImpl.new(right_available)

