require 'netplay/netplay_socket'
require 'sm_ram_map/state'
require 'sm_ram_map/room_ids'

require 'set'

class Super_Metroid_Autosplitter < Autosplitter
  UPGRADE_EVENTS = Set[
    :ammoPickups, :firstMissile, :allMissiles, :firstSuper,
    :allSupers, :firstPowerBomb, :allPowerBombs, :suitUpgrades,
    :beamUpgrades, :charge, :spazer, :wave, :ice, :plasma,
    :bootUpgrades, :hiJump, :spaceJump, :speedBooster, :energyUpgrades,
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
    :sporeSpawn, :crocomire, :botwoon, :phantoon, :draygon, :ridley,
    :mb1, :mb2, :mb3
  ]

  EVENTS = UPGRADE_EVENTS + ROOM_EVENTS + MISC_EVENTS + BOSS_EVENTS

  def initialize
    super
    # TODO: auto-reconnect socket
    @sock = NetplaySocket.new
    @state = nil
    @old_state = nil
    @log = [ ]
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
      allBeamUpgrades: new_beams.length > 0,
      charge: new_beams.include?(:charge),
      spazer: new_beams.include?(:spazer),
      wave: new_beams.include?(:wave),
      ice: new_beams.include?(:ice),
      plasma: new_beams.include?(:plasma),
      bootUpgrades: new_items.include?(:high_jump_boots) || new_items.include?(:space_jump) || new_items.include?(:speed_booster),
      hiJump: new_items.include?(:high_jump_boots),
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

    misc_events = {
      ceresEscape: @state.room_id == :ceresElevator && @old_state.game_state == :normal_start && @state.game_state == :startOfCeresCutscene,
      rtaFinish: (@state.event_flags & 0x40) > 0 && changes.ship_ai && @state.ship_ai == 0xaa4f,
      # TODO: sporeSpawnRTAFinish: in spore spawn room and picked up
      # spore spawn supsers and igt_frames has changed
    }

    boss_events = {
      bombTorizo: new_bosses.include?(:bomb_torizo),
      sporeSpawn: new_bosses.include?(:spore_spawn),
      ridley: new_bosses.include?(:ridley),
      crocomire: new_bosses.include?(:crocomire),
      phantoon: new_bosses.include?(:phantoon),
      draygon: new_bosses.include?(:draygon),
      botwoon: new_bosses.include?(:botwoon),
      mb1: @state.room_id == :motherBrain && @state.game_state == :normalGameplay && @old_state.mother_brain_hp == 0 && @old_state.mother_brain_hp == 18000,
      mb2: @state.room_id == :motherBrain && @state.game_state == :normalGameplay && @old_state.mother_brain_hp == 0 && @old_state.mother_brain_hp == 36000,
      mb3: new_bosses.include?(:mother_brain),
    }

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

    event_names = events.keys
    event_names.each { |name|
      # TODO: 56664Missiles not valid
      # raise "Invalid event: #{name}" if not EVENTS.include?(name)
    }

    if event_names.size > 0 then
      @last_events = event_names
      @log << event_names
    end

    return event_names
  end

  def current_events
    @last_events || [ ]
  end

  def debug
    s = ''
    s << "Room: #{@state.room_name}\n"
    s << "Items: #{@state.collected_items.inspect}\n"
    s << "Beams: #{@state.collected_beams.inspect}\n"
    s << "Most recent changes: #{@last_changes.to_h}\n"
    s << "Most recent events: #{@last_events}\n"
    s << "\n"
    s << "Last 20 events:\n"
    recent_events = @log.slice(-([@log.size, 20].min)..-1)
    recent_events.each { |l| s << "  #{l}\n" }
    return s
  end
end
