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
    :springBall, :screwAttack, :grapple, :xray
  ]

  # TODO: filter out rooms that don't have these items
  ROOM_EVENTS = Set.new(ROOM_IDS.values.map { |room_name|
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
  ]

  BOSS_EVENTS = [
    :bombTorizoFight, :sporeSpawnFight, :crocomireFight, :botwoonFight,
    :kraidFight, :phantoonFight, :draygonFight, :ridleyFight,
    :bombTorizoDead, :sporeSpawnDead, :crocomireDead, :botwoonDead,
    :kraidDead, :phantoonDead, :draygonDead, :ridleyDead,
    :anyMinibossFight, :anyMinibossDead, :anyBossFight, :anyBossDead,
    :mb1End, :mb2End, :mb3End, :motherBrainDead
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
  end

  def update
    @old_state = @state
    @state = State.read_from(@sock)
    update_events
  end

  def should_start
    return false if !@state || !@old_state

    old = @old_state.game_state_value
    new = @state.game_state_value

    normal_start = old == 2 && new == 0x1f
    cutscene_ended = old == 0x1e && new == 0x1f
    zebes_start = old == 5 && new == 6

    return normal_start || cutscene_ended || zebes_start
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
    }

    room_events = {
      :"#{@state.room_name}Missiles" => @state.max_missiles > @old_state.max_missiles,
      :"#{@state.room_name}Supers" => @state.max_supers > @old_state.max_supers,
      :"#{@state.room_name}PowerBombs" => @state.max_power_bombs > @old_state.max_power_bombs,
      :"#{@state.room_name}ETank" => @state.max_health > @old_state.max_health,
      :"#{@state.room_name}Reserve" => @state.max_reserve_tanks > @old_state.max_reserve_tanks,
      :"#{@state.room_name}" => changes.room_id,
    }

    room_events.clear if @state.room_name =~ /0x/

    misc_events = {
      ceresEscape: @state.room_name == :ceresElevator &&
                   @old_state.game_state == :normalGameplay &&
                   @state.game_state == :startOfCeresCutscene,
      rtaFinish: (@state.event_flags & 0x40) > 0 &&
                 changes.ship_ai && @state.ship_ai == 0xaa4f,
      # TODO: sporeSpawnRTAFinish: in spore spawn room and picked up
      # spore spawn supsers and igt_frames has changed
    }

    boss_events = {
      bombTorizoFight: @old_state.room_name != :bombTorizoRoom && @state.room_name == :bombTorizoRoom && !@state.bosses.include?(:bomb_torizo),
      sporeSpawnFight: @old_state.room_name != :sporeSpawnRoom && @state.room_name == :sporeSpawnRoom && !@state.bosses.include?(:bomb_torizo),
      kraidFight: @old_state.room_name != :kraidRoom && @state.room_name == :kraidRoom && !@state.bosses.include?(:kraid),
      phantoonFight: @old_state.room_name != :phantoonRoom && @state.room_name == :phantoonRoom && !@state.bosses.include?(:phantoon),
      botwoonFight: @old_state.room_name != :botwoonRoom && @state.room_name == :botwoonRoom && !@state.bosses.include?(:botwoon),
      draygonFight: @old_state.room_name != :draygonRoom && @state.room_name == :draygonRoom && !@state.bosses.include?(:draygon),
      crocomireFight: @old_state.room_name != :crocomireRoom && @state.room_name == :crocomireRoom && !@state.bosses.include?(:crocomire),
      ridleyFight: @old_state.room_name != :ridleyRoom && @state.room_name == :ridleyRoom && !@state.bosses.include?(:ridley),

      bombTorizoDead: new_bosses.include?(:bomb_torizo),
      sporeSpawnDead: new_bosses.include?(:spore_spawn),
      ridleyDead: new_bosses.include?(:ridley),
      crocomireDead: new_bosses.include?(:crocomire),
      phantoonDead: new_bosses.include?(:phantoon),
      draygonDead: new_bosses.include?(:draygon),
      botwoonDead: new_bosses.include?(:botwoon),
      mb1End: @state.room_name == :motherBrain && @state.game_state == :normalGameplay && @old_state.mother_brain_hp == 0 && @old_state.mother_brain_hp == 18000,
      mb2End: @state.room_name == :motherBrain && @state.game_state == :normalGameplay && @old_state.mother_brain_hp == 0 && @old_state.mother_brain_hp == 36000,
      mb3End: new_bosses.include?(:mother_brain),
      motherBrainDead: new_bosses.include?(:mother_brain),
    }

    boss_events.update(
      anyMinibossFight: boss_events[:bombTorizoFight] || boss_events[:sporeSpawnFight] || boss_events[:crocomireFight] || boss_events[:botwoonFight],
      anyBossFight: boss_events[:ridleyFight] || boss_events[:kraidFight] || boss_events[:phantoonFight] || boss_events[:draygonFight],
      anyMinibossDead: boss_events[:bombTorizoDead] || boss_events[:sporeSpawnDead] || boss_events[:crocomireDead] || boss_events[:botwoonDead],
      anyBossDead: boss_events[:ridleyDead] || boss_events[:kraidDead] || boss_events[:phantoonDead] || boss_events[:draygonDead],
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

    invalid_events = events.select { |k,v| !EVENTS.include?(k) }
    raise "Invalid events: #{invalid_events.inspect}" if not invalid_events.empty?

    events.delete_if { |k,v| !v }

    event_names = events.keys
    event_names.each { |name|
      # TODO: 56664Missiles not valid
      # raise "Invalid event: #{name}" if not EVENTS.include?(name)
    }

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
    s << "Room: #{@state.room_name}\n"
    s << "Game state: #{@state.game_state}\n"
    s << "Items: #{@state.collected_items.inspect}\n"
    s << "Beams: #{@state.collected_beams.inspect}\n"
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
end
