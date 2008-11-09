require File.dirname(__FILE__) + "/../http_impl.rb"

begin
  require 'eventmachine'

  eventmachine_available = true
  puts "eventmachine tests are available"
rescue LoadError
  eventmachine_available = false
  puts "eventmachine tests are not available (#{$!})"
end

class EventMachineHttpImpl < HttpImpl
  def initialize(eventmachine_available)
    super(__FILE__, "eventmachine", eventmachine_available)
  end

  protected

  def get_impl(uri, &block)
    EM.run {
        conn = EM::Protocols::HttpClient2.connect(uri.host, uri.port)
        req = conn.get(uri.path)
        req.callback {
            block.call req.content
            EM.stop
        }
    }
  end
end

EventMachineHttpImpl.new(eventmachine_available)
