require 'pty'
require 'shellwords'

class Toilet
  def initialize(font: nil, filters: [ ], filter: nil, format: nil, width: nil)
    filters = [ 'crop', *filters ]
    filters << filter if filter

    cmd = [ 'toilet' ]
    cmd << '-f' << font if font
    cmd << '-F' << filters.join(':')
    cmd << '-E' << format if format
    cmd << '-w' << width if width

    @height = `#{cmd.shelljoin} FOO`.lines.size

    @out, @in = PTY.spawn(*cmd)
  end

  def render(text)
    @in.puts(text)
    @out.gets # read echo
    s = [ ]
    @height.times do
      s << @out.gets.chomp
    end
    s.pop while s.last && s.last.strip == ''
    s.shift while s.first && s.first.strip == ''
    s
  end
end
