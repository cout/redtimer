$: << '.'
$: << 'lib'

require 'redtimer/curses_ui'
require 'redtimer/autosplitter'

require 'LiveSplitCore_ext/Run/read'

require 'LiveSplitCore'
require 'optparse'
require 'ostruct'
require 'json'

def create_run(opts)
  if opts.splits then
    run = LiveSplitCore::Run.read(opts.splits)
  else
    run = LiveSplitCore::Run.create
  end

  run.set_game_name(opts.game) if opts.game
  run.set_category_name(opts.category) if opts.category

  if opts.segments then
    opts.segments.each { |name| run.push_segment(LiveSplitCore::Segment.create(name)) }
  end

  raise "A run must have at least one segment" unless run.len > 0

  if opts.segment_times then
    editor = LiveSplitCore::RunEditor.create(run)
    opts.segment_times.each_with_index { |time, idx|
      editor.select_only(idx)
      editor.active_parse_and_set_segment_time(time)
    }
    run = editor.close
  end

  if opts.best_segment_times then
    editor = LiveSplitCore::RunEditor.create(run)
    opts.best_segment_times.each_with_index { |time, idx|
      editor.select_only(idx)
      editor.active_parse_and_set_best_segment_time(time)
    }
    run = editor.close
  end

  return run
end

def create_layout(opts)
  if opts.layout then
    s = File.read(opts.layout)
    layout = LiveSplitCore::Layout.parse_original_livesplit(s, s.length)
    raise "Unable to parse layout file `#{opts.layout}'" if not layout
  else
    layout = LiveSplitCore::Layout.default_layout
    layout.push(LiveSplitCore::SumOfBestComponent.create.into_generic)
  end

  return layout
end

if __FILE__ == $0 then
  opts = OpenStruct.new(
    timer_font: 'future')

  op = OptionParser.new
  op.on('-L', '--layout=FILENAME') { |a| opts.layout = a }
  op.on('-S', '--splits=FILENAME') { |a| opts.splits = a }
  op.on('-s', '--segments=SEGMENTS', Array) { |a| opts.segments = a }
  op.on('--game=NAME') { |a| opts.game = a }
  op.on('--category=NAME') { |a| opts.category = a }
  op.on('--segment-times=TIMES', Array) { |a| opts.segment_times = a }
  op.on('--best-segment-times=TIMES', Array) { |a| opts.best_segment_times = a }
  op.on('--timer-font=FONT') { |a| opts.timer_font = a }
  op.on('--autosplitter=SCRIPT') { |a| opts.autosplitter_script = a }
  op.on('--autosplitter-events=EVENTS', Array) { |a| opts.autosplitter_events = a }
  op.on('--autosplitter-debug') { |a| opts.autosplitter_debug = a }
  op.on('-C', '--config=FILENAME', Array) { |a| opts.config_files = a }
  op.parse!

  if opts.config_files then
    opts.config_files.each do |f|
      config = JSON.parse(File.read(f), symbolize_names: true)
      opts = OpenStruct.new(**config, **opts.to_h)
    end
  end

  run = create_run(opts)
  layout = create_layout(opts)
  timer = LiveSplitCore::Timer.create(run)

  raise "Could not create timer" if not timer

  if opts.autosplitter_script then
    autosplitter = Redtimer::Autosplitter.load(opts.autosplitter_script)
    # TODO: call configure here?
  end

  if autosplitter and opts.autosplitter_events then
    events = opts.autosplitter_events.map(&:to_sym)
    events.each do |e|
      raise "Unknown event #{e}" if not autosplitter.class::EVENTS.include?(e)
    end
    autosplitter.split_events.merge(events)
  end

  Redtimer::Curses_UI.run(
      opts: opts,
      layout: layout,
      timer: timer,
      autosplitter: autosplitter)
end
