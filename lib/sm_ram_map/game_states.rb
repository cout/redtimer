GAME_STATES = {
  0x06 => :loading,
  0x07 => :loading2,
  0x08 => :normalGameplay,
  0x0B => :doorTransition,
  0x0E => :pausing,
  0x0F => :inPauseMenu,
  0x10 => :leavingPauseMenu,
  0x12 => :leavingPauseMenu2,
  0x20 => :startOfCeresCutscene,
  0x21 => :ceresCutscene1,
  0x22 => :ceresCutscene2,
  0x26 => :preEndCutscene, # briefly at this value during the black screen transition after the ship fades out
  0x27 => :endCutscene,
}
