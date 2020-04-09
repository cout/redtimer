$: << 'lib'
require 'toilet'

if __FILE__ == $0 then
  sample_text = '123.04'

  fonts = `dpkg -L toilet-fonts`.lines.map!(&:chomp).select { |f| f =~ /\.tlf/ }.map { |f| File.basename(f).gsub(/\.tlf/, '') }

  fonts.each do |font, filename|
    puts "#{font}"
    puts "-" * font.length
    toilet = Toilet.new(format: 'utf8', filter: 'metal', font: font)
    puts toilet.render(sample_text)
    puts
  end
end
