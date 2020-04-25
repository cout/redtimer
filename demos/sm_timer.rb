$: << './lib'

require 'sm_ram_map/state'
require 'retroarch/network_command_socket'

require 'toilet'
require 'curses'

COLORS = [ [  40, -1 ], [  41, -1 ], [  42, -1 ] ]

def s_time(secs)
  h = '%d' % (secs.to_i / 3600)
  mm = '%02d' % ((secs.to_i % 3600) / 60)
  ss = '%02d' % (secs.to_i % 60)
  ff = '%02d' % ((secs * 100).to_i % 100)
  return "#{h}:#{mm}:#{ss}.#{ff}"
end

def render_timer(window, toilet, time, colors, prefix)
  lines = toilet.render(time)
  lines.each_with_index do |line, idx|
    color = colors[idx] || gradient_colors[-1]
    color_pair = Curses.color_pair(color)
    window.attron(color_pair) {
      window << prefix << line
    }
    window.clrtoeol
    window << "\n"
  end
end

if __FILE__ == $0 then
  screen = Curses.init_screen

  Curses.start_color
  Curses.use_default_colors
  Curses.curs_set(0)
  Curses.noecho

  window = Curses::Window.new(0, 0, 1, 2)
  window.timeout = 16.7
  window.clear
  width = [ window.maxx, 40 ].min

  colors = [ ]
  COLORS.each_with_index do |(fg, bg), idx|
    colors << idx + 1
    Curses.init_pair(idx + 1, fg, bg)
  end

  toilet = Toilet.new(format: 'utf8', font: 'future')

  sock = Retroarch::NetworkCommandSocket.new
  while true do
    state = State.read_from(sock)

    window.setpos(0, 0)
    render_timer(window, toilet, " IGT: " + s_time(state.igt), colors, "  ")
    render_timer(window, toilet, " RTA: " + s_time(state.rta), colors, "")
    window.refresh

    str = window.getch
    exit if str == 'q'
  end
end
