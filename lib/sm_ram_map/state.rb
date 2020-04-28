require_relative 'room_ids'
require_relative 'memory_region'
require_relative 'game_states'

require 'ostruct'

class State < OpenStruct
  def self.read_from(sock)
    region1 = MemoryRegion.read_from(sock, 0x0790, 0x1f)
    region2 = MemoryRegion.read_from(sock, 0x0990, 0xef)
    region3 = MemoryRegion.read_from(sock, 0xD800, 0x8f)
    region4 = MemoryRegion.read_from(sock, 0x0F80, 0x4f)
    region5 = MemoryRegion.read_from(sock, 0x05B0, 0x0f)

    room_id = region1.short(0x79B)
    game_state_value = region2.short(0x998)

    # Items/beams that are actually picked up.
    collected_items_bitmask = region2.short(0x9A4)
    collected_beams_bitmask = region2.short(0x9A8)

    max_health = region2.short(0x9C4)
    max_missiles = region2.short(0x9C8)
    max_supers = region2.short(0x9CC)
    max_power_bombs = region2.short(0x9D0)
    max_reserve_tanks = region2.short(0x9D6)

    igt_frames = region2.short(0x9DA)
    igt_seconds = region2[0x9DC]
    igt_minutes = region2[0x9DE]
    igt_hours = region2[0x9E0]
    fps = 60.0 # TODO

    # Varia randomizer RTA clock
    rta_frames = region5.short(0x5B8)
    rta_rollovers = region5.short(0x5BA)

    bosses_bitmask = region3.bignum(0xD828, 7)

    # Items that are in the inventory.
    items_bitmask = region3.bignum(0xD870, 15)

    event_flags = region3[0xD821]

    ship_ai = region4.short(0xFB2)
    mother_brain_hp = region4.short(0xFCC)

    collected_items = [ ]
    collected_items << :varia           if collected_items_bitmask & 0x0001 != 0
    collected_items << :spring_ball     if collected_items_bitmask & 0x0002 != 0
    collected_items << :morph_ball      if collected_items_bitmask & 0x0004 != 0
    collected_items << :screw_attack    if collected_items_bitmask & 0x0008 != 0
    collected_items << :gravity         if collected_items_bitmask & 0x0020 != 0
    collected_items << :high_jump_boots if collected_items_bitmask & 0x0100 != 0
    collected_items << :space_jump      if collected_items_bitmask & 0x0200 != 0
    collected_items << :bombs           if collected_items_bitmask & 0x1000 != 0
    collected_items << :speed_booster   if collected_items_bitmask & 0x2000 != 0
    collected_items << :grapple         if collected_items_bitmask & 0x4000 != 0
    collected_items << :xray            if collected_items_bitmask & 0x8000 != 0

    collected_beams = [ ]
    collected_beams << :charge          if collected_beams_bitmask & 0x1000 != 0
    collected_beams << :wave            if collected_beams_bitmask & 0x0001 != 0
    collected_beams << :ice             if collected_beams_bitmask & 0x0002 != 0
    collected_beams << :spazer          if collected_beams_bitmask & 0x0004 != 0
    collected_beams << :plasma          if collected_beams_bitmask & 0x0008 != 0

    bosses = [ ]
    bosses << :bomb_torizo              if bosses_bitmask & 0x00000000004 != 0
    bosses << :kraid                    if bosses_bitmask & 0x00000000100 != 0
    bosses << :spore_spawn              if bosses_bitmask & 0x00000000200 != 0
    bosses << :ridley                   if bosses_bitmask & 0x00000010000 != 0
    bosses << :crocomire                if bosses_bitmask & 0x00000020000 != 0
    bosses << :phantoon                 if bosses_bitmask & 0x00001000000 != 0
    bosses << :draygon                  if bosses_bitmask & 0x00100000000 != 0
    bosses << :botwoon                  if bosses_bitmask & 0x00200000000 != 0
    bosses << :mother_brain             if bosses_bitmask & 0x20000000000 != 0

    return self.new(
      room_id: room_id,
      room_name: ROOM_IDS[room_id] || ('0x%04x' % room_id),
      game_state_value: game_state_value,
      game_state: GAME_STATES[game_state_value] || ('0x%02x' % game_state_value),
      collected_items_bitmask: collected_items_bitmask,
      collected_items: collected_items,
      collected_beams_bitmask: collected_beams_bitmask,
      collected_beams: collected_beams,
      max_health: max_health,
      max_missiles: max_missiles,
      max_supers: max_supers,
      max_power_bombs: max_power_bombs,
      max_reserve_tanks: max_reserve_tanks,
      bosses_bitmask: bosses_bitmask,
      bosses: bosses,
      items_bitmask: items_bitmask,
      event_flags: event_flags,
      ship_ai: ship_ai,
      igt: igt_hours * 3600 + igt_minutes * 60 + igt_seconds + igt_frames / fps,
      rta: (rta_frames + (rta_rollovers << 16)) / 60.0,
    )
  end

  def ammo
    [ max_missiles, max_supers, max_bower_bombs ]
  end

  def suits
    items & [ :varia, :gravity ]
  end

  def boot_upgrades
    items & [ :high_jump_boots, :space_jump, :speed_booster ]
  end

  def each(&block)
    to_h.each(&block)
  end

  def changed?(old_state)
    self.class.new(each_pair.select { |k, v| old_state[k] != v }.to_h)
  end

  def inspect
    to_h
  end
end
