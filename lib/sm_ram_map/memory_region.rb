class MemoryRegion
  def initialize(addr, bytes)
    @start = addr
    @bytes = bytes
  end

  def self.read_from(sock, addr, len)
    bytes = sock.read_core_ram(addr, len) || [ ]
    return self.new(addr, bytes)
  end

  def [](addr)
    return @bytes[addr - @start] || 0
  end

  def short(addr)
    lo = self[addr] || 0
    hi = self[addr + 1] || 0
    lo | hi << 8
  end

  def bignum(addr, len)
    result = 0
    for i in 0..len do
      octet = self[addr + i] || 0
      result |= octet << (8 * i)
    end
    return result
  end
end
