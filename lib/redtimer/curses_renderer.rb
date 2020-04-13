require 'toilet'
require 'curses'

module Redtimer

class Curses_Renderer
  COLORS = {
    'Default'           =>   [   7, -1 ],
    'AheadGainingTime'  => [ [  40, -1 ], [  41, -1 ], [  42, -1 ] ],
    'AheadLosingTime'   => [ [ 148, -1 ], [ 149, -1 ], [ 150, -1 ] ],
    'BehindGainingTime' => [ [ 204, -1 ], [ 205, -1 ], [ 206, -1 ] ],
    'BehindLosingTime'  => [ [ 196, -1 ], [ 197, -1 ], [ 198, -1 ] ],
    'BestSegment'       =>   [ 214, -1 ],
    'NotRunning'        => [ [  40, -1 ], [  41, -1 ], [  42, -1 ] ],
    'Paused'            => [ [  40, -1 ], [  41, -1 ], [  42, -1 ] ],
    'PersonalBest'      => [ [  81, -1 ], [  80, -1 ], [  79, -1 ] ],
    'CurrentSplit'      =>   [   7, 25 ]
  }

  attr_reader :window

  def initialize(opts, window, colors)
    @window = window
    @colors = colors
    @width = [ @window.maxx, 40 ].min
    @toilet = Toilet.new(format: 'utf8', font: opts.timer_font)

    COLORS.each do |name, pairs|
      if pairs[0].is_a?(Array) then
        @colors.define_gradient(name, *pairs)
      else
        @colors.define(name, *pairs)
      end
    end
  end

  def render_title(component)
    game = component.line1 || ''
    category = component.line2 || ''
    attempts = component.attempts

    @window.attron(Curses::A_BOLD) {
      @window << game
      @window.clrtoeol
      @window << "\n"

      @window << category.ljust(@width - 8)
      @window << attempts.to_s.rjust(8) if component.shows_attempts 
      @window.clrtoeol
      @window << "\n"

      @window << "\u2500" * @width
      @window.clrtoeol
      @window << "\n"
    }
  end

  def render_with_semantic_color(name)
    color = semantic_color(name)
    color_pair = Curses.color_pair(color)
    @window.attron(color_pair) {
      yield
    }
  end

  def semantic_color(name)
    color = @colors[name]
    raise "No color defined for #{name}" if not color
    return color
  end

  def column_color(segment, column)
    if segment.current_split? then
      return semantic_color('CurrentSplit')
    else
      return semantic_color(column.semantic_color)
    end
  end

  def render_segment(name, segment, sep=false)
    name = '.' if name == ''
    name = name.force_encoding(Encoding::UTF_8)
    name_width = @width - segment.length * 8

    color = segment.current_split? \
      ? semantic_color('CurrentSplit') \
      : semantic_color('Default')

    bold = segment.current_split? ? Curses::A_BOLD : 0
    standout = sep ? Curses::A_UNDERLINE : 0
    attrs = bold | standout

    @window.attron(Curses.color_pair(color) | attrs) {
      num_spaces = [ 0, name_width - name.length ].max
      @window << name << ' ' * num_spaces
    }

    x = name_width
    segment.each_column do |column|
      @window.setpos(@window.cury, x)
      value = column.value.to_s.force_encoding(Encoding::UTF_8)
      value = '-' if value == ''
      color = column_color(segment, column)
      @window.attron(Curses.color_pair(color) | attrs) {
        @window << value.rjust(8)
      }
      x += 8
    end

    @window.clrtoeol
    @window << "\n"
  end

  def render_splits(component)
    component.each_segment.each_with_index do |(name, segment), idx|
      # Underline the next-to-last segment, as a separator.
      # TODO: I'd prefer this show as the last segment in italics, but I
      # don't know yet how to display italics in kitty.
      sep = component.final_separator_shown && idx == component.len - 2
      render_segment(name, segment, sep)
    end
  end

  def render_timer(component)
    gradient_colors = @colors.gradient(component.semantic_color).reverse
    s = "#{component.time}#{component.fraction}"
    lines = @toilet.render(s)
    width = lines.map { |line| line.length }.max
    prefix = ' ' * (@width - width)
    @toilet.render(s).each_with_index do |line, idx|
      color = gradient_colors[idx] || gradient_colors[-1]
      color_pair = Curses.color_pair(color)
      @window.attron(color_pair) {
        @window << prefix << line
      }
      @window.clrtoeol
      @window << "\n"
    end
  end

  def render_keyvalue(component)
    @window << component.key.ljust(@width - 8)
    render_with_semantic_color(component.semantic_color) {
      @window << component.value.to_s.rjust(8)
    }
    @window.clrtoeol
    @window << "\n"
  end

  def render_component(type, component)
    case type
    when 'Title' then render_title(component)
    when 'Splits' then render_splits(component)
    when 'Timer' then render_timer(component)
    when 'KeyValue' then render_keyvalue(component)
    end
    @window.refresh
  end

  def render_state(state)
    state.each do |type, component|
      render_component(type, component)
    end
  end
end

end
