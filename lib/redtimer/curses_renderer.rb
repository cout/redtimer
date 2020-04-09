require 'toilet'
require 'curses'

module Redtimer

class Curses_Renderer
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
    color = @colors[name]
    raise "No color defined for #{name}" if not color
    color_pair = Curses.color_pair(color)
    @window.attron(color_pair) {
      yield
    }
  end

  def render_splits(component)
    component.each_segment do |name, segment|
      name = '.' if name == ''
      name = name.force_encoding(Encoding::UTF_8)
      segment_width = @width - segment.length * 8
      num_spaces = [ 0, segment_width - name.length ].max
      @window << name << ' ' * num_spaces
      x = segment_width
      segment.each_column do |column|
        @window.setpos(@window.cury, x)
        render_with_semantic_color(column.semantic_color) {
          value = column.value.to_s.force_encoding(Encoding::UTF_8)
          value = '-' if value == ''
          @window << value.rjust(8)
          x += 8
        }
      end
      @window.clrtoeol
      @window << "\n"
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
      # render_ansi(line)
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

  def render_ansi(line)
    @window.clrtoeol
    puts "\r#{' ' * @window.begx}#{line}\r"
    @window.move_relative(0, 1) # TODO: this doesn't do what I thought it does!
    @window.refresh
  end

  def render_state(state)
    state.each do |type, component|
      render_component(type, component)
    end
  end
end

end
