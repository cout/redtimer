require 'socket'

class NetplaySocket
  def initialize(port=55354, addr='127.0.0.1')
    @sock = UDPSocket.new
    @sock.connect(addr, port)
  end

  def read
    @sock.read
  end

  def read_core_ram(addr, size)
    begin
      @sock.sendmsg("READ_CORE_RAM %x %d\n" % [ addr, size ])
      s, addrinfo, rflags, *controls = @sock.recvmsg
      return s.split[2..-1].map { |value| value.hex }
    rescue Errno::ECONNREFUSED
      return nil
    end
  end
end
