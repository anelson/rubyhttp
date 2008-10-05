#
# = net/http.rb
#
# Copyright (c) 1999-2006 Yukihiro Matsumoto
# Copyright (c) 1999-2006 Minero Aoki
# Copyright (c) 2001 GOTOU Yuuzou
# 
# Written and maintained by Minero Aoki <aamine@loveruby.net>.
# HTTPS support added by GOTOU Yuuzou <gotoyuzo@notwork.org>.
#
# This file is derived from "http-access.rb".
#
# Documented by Minero Aoki; converted to RDoc by William Webber.
# 
# This program is free software. You can re-distribute and/or
# modify this program under the same terms of ruby itself ---
# Ruby Distribution License or GNU General Public License.
#
# See Net::HTTP for an overview and examples. 
# 
# NOTE: You can find Japanese version of this document here:
# http://www.ruby-lang.org/ja/man/?cmd=view;name=net%2Fhttp.rb
# 
#--
# $Id: http.rb 13504 2007-09-24 08:12:24Z shyouhei $
#++ 

require File.dirname(__FILE__) + '/protocol'
require 'uri'

module Net   #:nodoc:
  class CustomHTTPSelect < HTTP

    def connect
      D "opening connection to #{conn_address()}..."
      s = timeout(@open_timeout) { TCPSocket.open(conn_address(), conn_port()) }
      D "opened"
      if use_ssl?
        unless @ssl_context.verify_mode
          warn "warning: peer certificate won't be verified in this SSL session"
          @ssl_context.verify_mode = OpenSSL::SSL::VERIFY_NONE
        end
        s = OpenSSL::SSL::SSLSocket.new(s, @ssl_context)
        s.sync_close = true
      end
      @socket = CustomBufferedIOSelect.new(s)
      @socket.read_timeout = @read_timeout
      @socket.debug_output = @debug_output
      if use_ssl?
        if proxy?
          @socket.writeline sprintf('CONNECT %s:%s HTTP/%s',
                                    @address, @port, HTTPVersion)
          @socket.writeline "Host: #{@address}:#{@port}"
          if proxy_user
            credential = ["#{proxy_user}:#{proxy_pass}"].pack('m')
            credential.delete!("\r\n")
            @socket.writeline "Proxy-Authorization: Basic #{credential}"
          end
          @socket.writeline ''
          HTTPResponse.read_new(@socket).value
        end
        s.connect
        if @ssl_context.verify_mode != OpenSSL::SSL::VERIFY_NONE
          begin
            s.post_connection_check(@address)
          rescue OpenSSL::SSL::SSLError => ex
            raise ex if @enable_post_connection_check
            warn ex.message
          end
        end
      end
      on_connect
    end
    protected :connect
  end
end   # module Net
