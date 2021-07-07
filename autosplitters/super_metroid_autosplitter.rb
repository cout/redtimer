require 'retroarch/network_command_socket'
require 'sm_ram_map/state'
require 'sm_ram_map/room_ids'

require 'set'

# An autosplitter for Super Metroid.  It is based UNHchabo's ASL-based
# autosplitter for livesplit
# (https://github.com/UNHchabo/AutoSplitters/tree/master/SuperMetroid).
class Super_Metroid_Autosplitter < Autosplitter
  UPGRADE_EVENTS = Set[
    :allAmmoPickups, :firstMissile, :allMissiles, :firstSuper,
    :allSupers, :firstPowerBomb, :allPowerBombs, :suitUpgrades,
    :anyBeamUpgrade, :charge, :spazer, :wave, :ice, :plasma,
    :anyBootUpgrade, :highJumpBoots, :spaceJump, :speedBooster, :allEnergyUpgrades,
    :firstETank, :allETanks, :reserveTanks, :morphBall, :bombs,
    :springBall, :screwAttack, :grapple, :xray, :varia, :gravity
  ]

  ROOM_NAMES = Set.new(ROOM_IDS.values.map { |name| name.to_s })

  CAPITALIZED_ROOM_NAMES = Set.new(ROOM_NAMES.map { |name|
    name.sub(/./, &:upcase)
  })

  VALID_ROOM_IDS_RE = /(0x[A-Fa-f0-9]+|#{(ROOM_NAMES + CAPITALIZED_ROOM_NAMES).to_a.join('|')})/

  # TODO: filter out rooms that don't have these items
  ROOM_EVENTS = Set.new(ROOM_NAMES.map { |room_name|
    [
      :"#{room_name}",
      :"#{room_name}Missiles",
      :"#{room_name}Supers",
      :"#{room_name}PowerBombs",
      :"#{room_name}ETank",
      :"#{room_name}Reserve",
    ]
  }.flatten)

  MISC_EVENTS = [
    :ceresEscape,
    :rtaFinish,
    :hundredMissileRTAFinish,
  ]

  MINI_BOSSES = [
    "bombTorizo", "sporeSpawn", "crocomire", "botwoon", "goldenTorizo"
  ]

  BOSSES = [
    "kraid", "phantoon", "ridley", "draygon", "motherBrain"
  ]

  BOSS_EVENTS = [
    *MINI_BOSSES.map { |name| :"#{name}Fight" },
    *MINI_BOSSES.map { |name| :"#{name}Dead" },
    *BOSSES.map { |name| :"#{name}Fight" },
    *BOSSES.map { |name| :"#{name}Dead" },
    :anyMinibossFight, :anyMinibossDead, :anyBossFight, :anyBossDead,
    :mb1End, :mb2End, :mb3End,
  ]

  EVENTS = UPGRADE_EVENTS + ROOM_EVENTS + MISC_EVENTS + BOSS_EVENTS

  def initialize
    super
    # TODO: auto-reconnect socket
    @sock = Retroarch::NetworkCommandSocket.new
    @state = nil
    @old_state = nil
    @log = [ ]
    @splits = [ ]
    @emulator_paused = nil
  end

  def update
    @emulator_status = @sock.get_status
    @emulator_paused = @sock.paused?

    @old_state = @state
    new_state = State.read_from(@sock)
    if playing?(new_state) or not @old_state then
      state = new_state
    else
      state = State.new(@old_state.to_h)
      state.game_state_value = new_state.game_state_value
      state.game_state = new_state.game_state
    end
    @state = state
    update_events
  end

  def playing?(state)
    s = state.game_state
    s >= GameState::NormalGameplay && s <= GameState::EndCutscene
  end

  def should_start
    return false if !@state || !@old_state

    old = @old_state.game_state
    new = @state.game_state
    transition = [ old, new ]

    @log << "state transition: " << transition if old != new

    normal_start = transition == [ GameState::OptionMode, GameState::GameStarting ]
    cutscene_ended = transition == [ GameState::CutsceneEnding, GameState::GameStarting ]
    zebes_start = transition == [ GameState::LoadArea, GameState::Loading ]

    return normal_start || cutscene_ended || zebes_start
  end

  def should_pause
    return @emulator_paused
  end

  def should_resume
    return !@emulator_paused
  end

  def update_events
    return if !@state || !@old_state

    changes = @state.changed?(@old_state)
    @last_changes = changes

    new_items = @state.collected_items - @old_state.collected_items
    new_beams = @state.collected_beams - @old_state.collected_beams
    new_bosses = @state.bosses - @old_state.bosses

    upgrade_events = {
      allAmmoPickups: @old_state.ammo != @state.ammo,
      firstMissile: @old_state.max_missiles == 0 && changes.max_missiles,
      allMissiles: @state.max_missiles > @old_state.max_missiles,
      firstSuper: @old_state.max_supers == 0 && changes.max_supers,
      allSupers: @state.max_supers > @old_state.max_supers,
      firstPowerBomb: @old_state.max_power_bombs == 0 && changes.max_power_bombs,
      allPowerBombs: @state.max_power_bombs > @old_state.max_power_bombs,
      suitUpgrades: new_items.include?(:varia) || new_items.include?(:gravity),
      anyBeamUpgrade: new_beams.length > 0,
      charge: new_beams.include?(:charge),
      spazer: new_beams.include?(:spazer),
      wave: new_beams.include?(:wave),
      ice: new_beams.include?(:ice),
      plasma: new_beams.include?(:plasma),
      anyBootUpgrade: new_items.include?(:high_jump_boots) || new_items.include?(:space_jump) || new_items.include?(:speed_booster),
      highJumpBoots: new_items.include?(:high_jump_boots),
      spaceJump: new_items.include?(:space_jump),
      speedBooster: new_items.include?(:speed_booster),
      allEnergyUpgrades: @state.max_health > @old_state.max_health || @state.max_reserve_tanks > @old_state.max_reserve_tanks,
      firstETank: @old_state.max_health < 100 && changes.max_health,
      allETanks: @state.max_health > @old_state.max_health,
      reserveTanks: @state.max_reserve_tanks > @old_state.max_reserve_tanks,
      morphBall: new_items.include?(:morph_ball),
      bombs: new_items.include?(:bombs),
      springBall: new_items.include?(:spring_ball),
      screwAttack: new_items.include?(:screw_attack),
      grapple: new_items.include?(:grapple),
      xray: new_items.include?(:xray),
      varia: new_items.include?(:varia),
      gravity: new_items.include?(:gravity),
    }

    # Exclude upgrades that were acquired as a result of GT code
    if @state.room_name == :goldenTorizo or @state.room_name == :screwAttackRoom then
      upgrade_events = upgrade_events.map { |name, value| [ name, false ] }.to_h
    end

    room_events = {
      :"#{@state.room_name}Missiles" => @state.max_missiles > @old_state.max_missiles,
      :"#{@state.room_name}Supers" => @state.max_supers > @old_state.max_supers,
      :"#{@state.room_name}PowerBombs" => @state.max_power_bombs > @old_state.max_power_bombs,
      :"#{@state.room_name}ETank" => @state.max_health > @old_state.max_health,
      :"#{@state.room_name}Reserve" => @state.max_reserve_tanks > @old_state.max_reserve_tanks,
      :"#{@state.room_name}" => changes.room_id,
      :"#{@old_state.room_name}To#{@state.room_name.to_s.sub(/./, &:upcase)}" => changes.room_id,
    }

    room_events.clear if @state.room_name =~ /0x/

    misc_events = {
      ceresEscape: @state.room_name == :ceresElevator &&
                   @old_state.game_state == GameState::NormalGameplay &&
                   @state.game_state == GameState::StartOfCeresCutscene,
      rtaFinish: (@state.event_flags & 0x40) > 0 &&
                 changes.ship_ai && @state.ship_ai == 0xaa4f,
      hundredMissileRTAFinish: @old_state.max_missiles < 100 && @state.max_missiles >= 100,
      # TODO: sporeSpawnRTAFinish: in spore spawn room and picked up
      # spore spawn supsers and igt_frames has changed
    }

    boss_events = {
      bombTorizoFight: @old_state.room_name != :bombTorizoRoom && @state.room_name == :bombTorizoRoom && !@state.bosses.include?(:bomb_torizo),
      sporeSpawnFight: @old_state.room_name != :sporeSpawnRoom && @state.room_name == :sporeSpawnRoom && !@state.bosses.include?(:spore_spawn),
      kraidFight: @old_state.room_name != :kraidRoom && @state.room_name == :kraidRoom && !@state.bosses.include?(:kraid),
      phantoonFight: @old_state.room_name != :phantoonRoom && @state.room_name == :phantoonRoom && !@state.bosses.include?(:phantoon),
      botwoonFight: @old_state.room_name != :botwoonRoom && @state.room_name == :botwoonRoom && !@state.bosses.include?(:botwoon),
      draygonFight: @old_state.room_name != :draygonRoom && @state.room_name == :draygonRoom && !@state.bosses.include?(:draygon),
      crocomireFight: @old_state.room_name != :crocomireRoom && @state.room_name == :crocomireRoom && !@state.bosses.include?(:crocomire),
      goldenTorizoFight: @old_state.room_name != :goldenTorizo && @state.room_name == :goldenTorizo && !@state.bosses.include?(:goldenTorizo),
      ridleyFight: @old_state.room_name != :ridleyRoom && @state.room_name == :ridleyRoom && !@state.bosses.include?(:ridley),
      motherBrainFight: @old_state.room_name != :motherBrain && @state.room_name == :motherBrain && !@state.bosses.include?(:motherBrain),

      bombTorizoDead: new_bosses.include?(:bomb_torizo),
      sporeSpawnDead: new_bosses.include?(:spore_spawn),
      ridleyDead: new_bosses.include?(:ridley),
      crocomireDead: new_bosses.include?(:crocomire),
      phantoonDead: new_bosses.include?(:phantoon),
      draygonDead: new_bosses.include?(:draygon),
      botwoonDead: new_bosses.include?(:botwoon),
      goldenTorizoDead: new_bosses.include?(:goldenTorizo),
      mb1End: @state.room_name == :motherBrain && @state.game_state == GameState::NormalGameplay && @old_state.mother_brain_hp == 0 && @old_state.mother_brain_hp == 18000,
      mb2End: @state.room_name == :motherBrain && @state.game_state == GameState::NormalGameplay && @old_state.mother_brain_hp == 0 && @old_state.mother_brain_hp == 36000,
      mb3End: new_bosses.include?(:mother_brain),
      motherBrainDead: new_bosses.include?(:mother_brain),
    }

    boss_events.update(
      anyMinibossFight: boss_events[:bombTorizoFight] || boss_events[:sporeSpawnFight] || boss_events[:crocomireFight] || boss_events[:botwoonFight] || boss_events[:goldenTorizoFight],
      anyBossFight: boss_events[:ridleyFight] || boss_events[:kraidFight] || boss_events[:phantoonFight] || boss_events[:draygonFight] || boss_events[:motherBrainFight],
      anyMinibossDead: boss_events[:bombTorizoDead] || boss_events[:sporeSpawnDead] || boss_events[:crocomireDead] || boss_events[:botwoonDead] || boss_events[:goldenTorizoDead],
      anyBossDead: boss_events[:ridleyDead] || boss_events[:kraidDead] || boss_events[:phantoonDead] || boss_events[:draygonDead] || boss_events[:motherBrainDead],
    )

    events = { }
    events.update(upgrade_events)
    events.update(room_events)
    events.update(misc_events)
    events.update(boss_events)

    # TODO: area transitions
    # TODO: rtaFinish
    # TODO: igtFinish
    # TODO: sporeSpawnRTAFinish
    # TODO: hundredMissileRTAFinish

    events.delete_if { |k,v| !v }

    invalid_events = events.keys.select { |event| !valid_event?(event) }
    raise "Invalid events: #{invalid_events.inspect}" if not invalid_events.empty?

    event_names = events.keys

    if event_names.size > 0 then
      @last_events = event_names
      @log << event_names
    else
      @last_events = nil
    end

    return event_names
  end

  def current_events
    @last_events || [ ]
  end

  def should_split
    result = super
    @splits << @last_events if result
    return result
  end

  def debug
    s = ''
    if @state then
      s << "Emulator status: #{@emulator_status}\n"
      s << "Emulator paused: #{@emulator_paused}\n"
      s << "Room: #{@state.room_name}\n"
      s << "Game state: #{@state.game_state}\n"
      s << "Items: #{@state.collected_items.inspect}\n"
      s << "Beams: #{@state.collected_beams.inspect}\n"
      s << "Tanks: #{@state.max_health} Reserve: #{@state.max_reserve_tanks}\n"
    end
    s << "Most recent changes: #{@last_changes.to_h}\n"
    s << "Most recent events: #{@last_events}\n"
    s << "\n"
    s << "Last 10 events:\n"
    recent_events = @log.slice(-([@log.size, 10].min)..-1)
    recent_events.each { |l| s << "  #{l}\n" }
    s << "\n"
    s << "Last 10 splits:\n"
    recent_splits = @splits.slice(-([@splits.size, 10].min)..-1)
    @splits.each { |split| s << "  #{split}\n" }
    return s
  end

  def valid_event?(event)
    EVENTS.include?(event) || valid_transition_event?(event)
  end

  def valid_transition_event?(event)
    event =~ /^#{VALID_ROOM_IDS_RE}To#{VALID_ROOM_IDS_RE}$/
  end

  def valid_room?(name)
    ROOM_NAMES.include?(name) ||
    CAPITALIZED_ROOM_NAMES.include?(name) ||
    name =~ /0x[A-Fa-f0-9]+/
  end
end
