#
# = net/protocol.rb
#
#--
# Copyright (c) 1999-2005 Yukihiro Matsumoto
# Copyright (c) 1999-2005 Minero Aoki
#
# written and maintained by Minero Aoki <aamine@loveruby.net>
#
# This program is free software. You can re-distribute and/or
# modify this program under the same terms as Ruby itself,
# Ruby Distribute License or GNU General Public License.
#
# $Id: protocol.rb 11708 2007-02-12 23:01:19Z shyouhei $
#++
#
# WARNING: This file is going to remove.
# Do not rely on the implementation written in this file.
#

require 'socket'
require 'timeout'
require 'net/protocol'

module Net # :nodoc:

  class CustomBufferedIOSelect < BufferedIO   #:nodoc: internal use only
    def initialize(io)
      super(io)
    end

    private

    BUFSIZE = 1024*16

    def rbuf_fill
      begin
        @rbuf << @io.read_nonblock(BUFSIZE)
      rescue Errno::EWOULDBLOCK
        if IO.select([@io], nil, nil, @read_timeout)
          @rbuf << @io.read_nonblock(BUFSIZE)
        else
          raise Timeout::TimeoutError
        end
      end

    end
  end
end   # module Net

