class GameState
  include Comparable

  attr_reader :name
  attr_reader :value

  def initialize(value, name)
    @value = value
    @name = name
  end

  def to_s
    @name.to_s
  end

  def <=>(other)
    @value <=> other.value
  end

  @by_value = { }
  @by_name = { }

  class << self
    attr_reader :by_value
    attr_reader :by_name

    def def(value, name)
      state = GameState.new(value, name)
      GameState.const_set(name, state)
      @by_value[value] = state
      @by_name[name] = state
    end
  end
end

GameState.def 0x00, :Off
GameState.def 0x01, :TitleScreen
GameState.def 0x02, :OptionMode
GameState.def 0x04, :SelectSavedGame
GameState.def 0x05, :LoadArea
GameState.def 0x06, :Loading
GameState.def 0x07, :Loading2
GameState.def 0x08, :NormalGameplay
GameState.def 0x0B, :DoorTransition
GameState.def 0x0E, :Pausing
GameState.def 0x0F, :InPauseMenu
GameState.def 0x10, :LeavingPauseMenu
GameState.def 0x12, :LeavingPauseMenu2
GameState.def 0x15, :Dying
GameState.def 0x16, :Dying2
GameState.def 0x17, :Dying3
GameState.def 0x18, :Dying4
GameState.def 0x19, :Dying5
GameState.def 0x1a, :GameOver
GameState.def 0x1e, :CutsceneEnding
GameState.def 0x1f, :GameStarting
GameState.def 0x20, :StartOfCeresCutscene
GameState.def 0x21, :CeresCutscene1
GameState.def 0x22, :CeresCutscene2
GameState.def 0x23, :TimerUp
GameState.def 0x24, :BlackoutAndGameover
GameState.def 0x26, :PreEndCutscene # briefly at this value during the black screen transition after the ship fades out
GameState.def 0x27, :EndCutscene
GameState.def 0x28, :LoadingDemo
GameState.def 0x2a, :PlayingDemo
