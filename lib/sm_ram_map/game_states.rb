GAME_STATES = {
  loading:                 0x06,
  loading2:                0x07, # ?
  normalGameplay:          0x08,
  doorTransition:          0x0B,
  pausing:                 0x0E,
  inPauseMenu:             0x0F,
  leavingPauseMenu:        0x10,
  leavingPauseMenu2:       0x12, # ?
  startOfCeresCutscene:    0x20,
  preEndCutscene:          0x26, # briefly at this value during the black screen transition after the ship fades out
  endCutscene:             0x27,
}
