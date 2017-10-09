struct Action
  @opcode : Int32

  def initialize(op : Int32 = -1)
    @opcode = op
  end

  def initialize(move_op)
    @opcode = move_op
  end

  def initialize(pos, place tile)
    @opcode = (tile << 4) | pos
  end

  def to_i
    @opcode
  end

  def apply!(b : Board*)
    if (0b11 & @opcode) == @opcode # human
      b.value.move!(@opcode)
    elsif (b.value[@opcode & 0x0f]) == 0
      b.value[@opcode & 0x0f] = @opcode >> 4
      0
    else
      -1
    end
  end

  def name
    if ((0b11 & @opcode) == @opcode)
      opname = {"up", "right", "down", "left"}
      return "slide #{opname[opcode]}"
    else
      return "place #{@opcode >> 4}-index at position #{@opcode & 0x0f}"
    end
  end
end
