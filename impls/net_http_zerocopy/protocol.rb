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

  class CustomBufferedIOZeroCopy < BufferedIO   #:nodoc: internal use only
    BUFSIZE = 1024*16

    def initialize(io)
      super(io)
    end

    def read(len, dest = '', ignore_eof = false)
      #In a clear violation of the principle of Least Surprise, Net::HTTP
      #will pass a regular array in to dest if the user doesn't provide a block
      #to which results will be yielded.  If a block is provided, dest is a ReadAdapter
      #object, which implements '<<' by yielding the buffer to a proc.
      #Unfortunately,  this complicates the optimization.
      #
      #To test out the zero-copy idea, ignore the rules of Duck Typing and explicitly
      #look for the ReadAdapter
      if dest.class == ReadAdapter
        read_adapter(len, dest, ignore_eof)
      else
        read_old(len, dest, ignore_eof)
      end
    end

    def read_adapter(len, dest = '', ignore_eof = false)
      LOG "reading #{len} bytes..."
      read_bytes = 0
      begin
        #If there's anything left in @rbuf, process that
        #it's a copy hit, but there won't be much left over at the buffer
        #is only 16k
        s = rbuf_consume(len)
        dest << s
        read_bytes += s.length

        #Allocate a single buffer for all subsequent reads
        buf = ""

        while read_bytes < len
          socket_read(buf, (len-read_bytes > BUFSIZE ? BUFSIZE : len-read_bytes))
          dest << buf
          read_bytes += buf.size
        end
      rescue EOFError
        raise unless ignore_eof
      end
      LOG "read #{read_bytes} bytes"
      dest
    end

    def read_old(len, dest = '', ignore_eof = false)
      LOG "reading #{len} bytes..."
      read_bytes = 0
      begin
        while read_bytes + @rbuf.size < len
          dest << (s = rbuf_consume(@rbuf.size))
          read_bytes += s.size
          rbuf_fill
        end
        dest << (s = rbuf_consume(len - read_bytes))
        read_bytes += s.size
      rescue EOFError
        raise unless ignore_eof
      end
      LOG "read #{read_bytes} bytes"
      dest
    end

    protected

    def socket_read(buf, len)
      begin
        @io.read_nonblock(len, buf)
      rescue Errno::EWOULDBLOCK
        if IO.select([@io], nil, nil, @read_timeout)
          @io.read_nonblock(len, buf)
        else
          raise Timeout::TimeoutError
        end
      end
    end

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

