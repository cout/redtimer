$: << './lib'

require 'sm_ram_map/state'
require 'retroarch/network_command_socket'

require 'ostruct'

if __FILE__ == $0 then
  old_state = State.new

  sock = Retroarch::NetworkCommandSocket.new
  while true do
    state = State.read_from(sock)

    state.changed?(old_state).each do |k, v|
      v = '%x' % v if k =~ /mask/
      puts "#{k} changed to #{v}"
    end

    old_state = state

    sleep 1
  end
end
