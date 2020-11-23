GAME_STATES = {
  0x00 => :off,
  0x01 => :titleScreen,
  0x02 => :optionMode,
  0x04 => :selectSavedGame,
  0x06 => :loading,
  0x07 => :loading2,
  0x08 => :normalGameplay,
  0x0B => :doorTransition,
  0x0E => :pausing,
  0x0F => :inPauseMenu,
  0x10 => :leavingPauseMenu,
  0x12 => :leavingPauseMenu2,
  0x17 => :dying1,
  0x18 => :dying2,
  0x19 => :dying3,
  0x1a => :gameOver,
  0x20 => :startOfCeresCutscene,
  0x21 => :ceresCutscene1,
  0x22 => :ceresCutscene2,
  0x26 => :preEndCutscene, # briefly at this value during the black screen transition after the ship fades out
  0x27 => :endCutscene,
  0x28 => :loadingDemo,
  0x2a => :playingDemo,
}

GAME_STATE_NAMES = GAME_STATES.invert
