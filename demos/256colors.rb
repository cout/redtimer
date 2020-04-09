require 'curses'

screen = Curses.init_screen

begin
  Curses.start_color
  Curses.use_default_colors
  Curses.curs_set(0)
  Curses.noecho

  window = Curses::Window.new(0, 0, 1, 2)

  window.clear
  window.setpos(0, 0)

  for i in 0...256 do
    Curses.init_pair(i, i, 0)
    window.color_set(i)
    window << i.to_s << ' '
  end

  window.getch
ensure
  Curses.close_screen
end
