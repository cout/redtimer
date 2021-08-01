require 'socket'

module Retroarch

class NetworkCommandSocket
  attr_reader :sock

  def initialize(port=55355, addr='127.0.0.1', alt_port=55354)
    connect(port, addr, alt_port)
  end

  def connect(port, addr, alt_port)
    connected = false

    loop do
      @sock = UDPSocket.new
      @sock.connect(addr, port)
      break if get_status

      puts "Did not connect; trying again on port #{alt_port}"
      port, alt_port = alt_port, port
      sleep 1
    end
  end

  def send_command(msg)
    begin
      # TODO: msg should not contain \n, else we need to read multiple
      # responses
      @sock.sendmsg(msg)
      res = IO.select([@sock], nil, nil, 1)
      if res
        s, addrinfo, rflags, *controls = @sock.recvmsg
        cmd, response = s.split(/ /, 2)
        return response
      else
        return nil
      end
    rescue Errno::ECONNREFUSED
      return nil
    end
  end

  def read
    @sock.read
  end

  def read_core_ram(addr, size)
    response = send_command("READ_CORE_RAM %x %d\n" % [ addr, size ])
    if response then
      return response.split[1..-1].map { |value| value.hex }
    else
      return nil
    end
  end

  class Status < Struct.new(:state, :content); end

  def get_status
    response = send_command("GET_STATUS")
    if response then
      state, content = response.split
      return Status.new(state, content ? content.split(',') : nil)
    else
      return nil
    end
  end

  def paused?
    status = get_status
    if status then
      return status.state == 'PAUSED'
    else
      return nil
    end
  end

end

end
