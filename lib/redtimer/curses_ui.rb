require_relative 'curses_renderer'
require_relative 'color_pairs'

require 'LiveSplitCore_ext/LayoutStateRef/each'
require 'LiveSplitCore_ext/SplitsComponentStateRef/each'

require 'curses'

module Redtimer

COLORS = {
  'Default'           =>   [ 7,   0 ],
  'AheadGainingTime'  => [ [ 40,  0 ], [ 41,  0 ], [ 42,  0 ] ],
  'AheadLosingTime'   => [ [ 148, 0 ], [ 149, 0 ], [ 150, 0 ] ],
  'BehindGainingTime' => [ [ 204, 0 ], [ 205, 0 ], [ 206, 0 ] ],
  'BehindLosingTime'  => [ [ 196, 0 ], [ 197, 0 ], [ 198, 0 ] ],
  'BestSegment'       =>   [ 214, 0 ],
  'NotRunning'        => [ [ 40,  0 ], [ 41,  0 ], [ 42,  0 ] ],
  'Paused'            => [ [ 40,  0 ], [ 41,  0 ], [ 42,  0 ] ],
  'PersonalBest'      => [ [ 81,  0 ], [ 80,  0 ], [ 79,  0 ] ],
}

class Curses_UI
  def initialize(screen:, opts:, run:, layout:, timer:, autosplitter:)
    @screen = screen
    @opts = opts
    @window = Curses::Window.new(0, 0, 1, 2)
    @window.clear
    @window.timeout = 100

    @colors = Color_Pairs.new
    @renderer = Curses_Renderer.new(@opts, @window, @colors)

    @opts = opts
    @run = run
    @layout = layout
    @timer = timer
    @autosplitter = autosplitter
  end

  def self.run(*args, **kwargs)
    screen = Curses.init_screen

    begin
      Curses.start_color
      Curses.use_default_colors
      Curses.curs_set(0)
      Curses.noecho

      ui = Curses_UI.new(*args, screen: screen, **kwargs)
      ui.run

    ensure
      Curses.close_screen
    end
  end

  def run
    loop do
      @window.setpos(0, 0)
      state = @layout.state(@timer)
      @renderer.render_state(state)

      process_input
      autosplit
    end
  end

  def process_input
    str = @window.getch.to_s
    case str
    when ' ' then @timer.toggle_pause_or_start
    when 's' then @timer.skip_split
    when 'u' then @timer.undo_split
    when 'p' then @timer.pause
    when 'r' then reset
    when 'q' then quit
    when '10' then @timer.split
    end
  end

  def autosplit
    if @autosplitter then
      @autosplitter.update

      if @opts.autosplitter_debug then
        debug = @autosplitter.debug
        @window << debug << "\n" if debug
      end

      @timer.start if @autosplitter.should_start
      @timer.split if @autosplitter.should_split
      @timer.reset if @autosplitter.should_reset

      # TODO: do something with is_loading?
      # TODO: update game_time
    end
    @window.refresh
  end

  def quit
    if yesno("Are you sure you want to quit? (Y/N)") then
      exit
    end
  end

  def reset
    # TODO: detect if beaten personal best
    if yesno("Your splits (may) have changed. Do you want to save? (Y/N)") then
      @timer.reset(true)
      # TODO: save
    else
      @timer.reset(false)
    end
  end

  def yesno(text)
    @window << "\n" << text
    @window.refresh
    begin
      loop do
        str = @window.getch.to_s.upcase
        return true if str == 'Y'
        return false if str == 'N'
      end
    ensure
      @window << "\r"
      @window.clrtoeol
      @window.setpos(@window.cury - 1, 0)
    end
  end
end

end
