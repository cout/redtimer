require 'LiveSplitCore'

class LiveSplitCore::Timer
  module Phase
    NotRunning = 0
    Running = 1
    Ended = 2
    Paused = 3
  end
end
