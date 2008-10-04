require File.dirname(__FILE__) + "/../http_impl.rb"

begin
  require 'curb'
  curb_available = true
  puts "libcurl tests are available"
rescue LoadError
  curb_available = false
  puts "libcurl tests are not available (#{$!})"
end

class CurlHttpImpl < HttpImpl
  def initialize(curb_available)
    super("libcurl", curb_available)
  end

  protected

  def get_impl(uri, &block)
    c = Curl::Easy.new(uri.to_s)
    c.on_body do |body|
      block.call body
      body.length
    end

    c.perform
  end
end

CurlHttpImpl.new(curb_available)
