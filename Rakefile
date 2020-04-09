require 'open3'

task :record do
  cmd = "bundle exec ruby redtimer.rb \\\n--game 'Lucky Charms' \\\n--category '1983 Edition' \\\n-s '\xF0\x9F\x92\x97 Pink Hearts,\xf0\x9f\x8c\x99 Yellow Moons,\xe2\xad\x90 Orange Stars,\xf0\x9f\x8d\x80 Green Clovers,\xf0\x9f\xa7\xb2 Purple Horseshoes'"

  Open3.pipeline_w("termtosvg docs/redtimer.svg -g 44x25 -D 4000 -c \"#{cmd}\"") do |stdin, th|
    # Start the timer
    sleep 1
    stdin << " "
    stdin.flush

    # Split
    6.times do
      sleep 2 + rand
      stdin << "\n"
      stdin.flush
    end
  end

  sh 'reset'
end

file 'docs/redtimer.svg' do
  Rake::Task[:record].invoke
end
