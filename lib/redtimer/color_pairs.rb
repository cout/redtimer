module Redtimer

class Color_Pairs
  def initialize
    @next = 1
    @colors = { }
    @gradients = { }
  end

  def define(name, fg, bg)
    raise "No foreground color given" if not fg
    raise "No background color given" if not bg
    Curses.init_pair(@next, fg, bg)
    @colors[name] = @next
    @next += 1
  end

  def define_gradient(name, *pairs)
    names = [ ]
    pairs.each_with_index do |pair, idx|
      n = idx == 0 ? name : "#{name}-#{idx}"
      define(n, *pair)
      names << n
    end
    @gradients[name] = names
  end

  def [](name)
    @colors[name]
  end

  def gradient(name)
    gradient = @gradients[name]
    raise "No such gradient #{name}" if not gradient
    gradient.map { |name| self[name] }
  end
end

end
