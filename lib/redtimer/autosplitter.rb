module Redtimer

# https://cdn.discordapp.com/attachments/444485391823667200/694570570330800248/unknown.png
class Autosplitter
  class << self
    attr_reader :autosplitters
  end

  @autosplitters = [ ]

  def self.inherited(klass)
    self.autosplitters << klass
  end

  def self.load(filename)
    Loader.new.load(filename)
    return autosplitters.last.new
  end

  attr_accessor :split_events

  def initialize
    @split_events = Set[]
  end

  def update
  end

  def current_events
    [ ]
  end

  def should_start
    false
  end

  def should_split
    current_events.any? { |event| @split_events.include?(event) }
  end

  def should_reset
    false
  end

  def is_loading
    false
  end

  def game_time
    return Float::NAN
  end

  def configure
  end

  def debug
    nil
  end
end

class Autosplitter::Loader < Module
  def load(filename)
    s = File.read(filename)
    self.class_eval(s, filename)
  end
end

end
