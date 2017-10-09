require "./environment"

struct Board
  include Indexable(Int32)

  property board : StaticArray(Int32, 16)

  def initialize(@board : StaticArray(Int32, 16) = StaticArray(Int32, 16).new 0)
  end

  def ==(b : Board)
    board == b.board
  end

  def ==(b : StaticArray(Int32, 16))
    board == b
  end

  def size
    16
  end

  def unsafe_at(index : Int)
    @board[index]
  end

  def [](tile_number)
    @board[tile_number]
  end

  def [](row, col)
    @board[(row << 2) + col]
  end

  def []=(tile_number, value)
    @board[tile_number] = value
  end

  def []=(row, col, value)
    @board[(row << 2) + col] = value
  end

  def transpose!
    1.upto(3) do |row|
      row.times do |col|
        self.[row, col], self.[col, row] = self.[col, row], self.[row, col]
      end
    end
  end

  def transpose2!
    3.times do |row|
      (3 - row).times do |col|
        self.[row, col], self.[3 - col, 3 - row] = self.[3 - col, 3 - row], self.[row, col]
      end
    end
  end

  def reflect_horizonal!
    0.upto(3) do |row|
      self.[row, 0], self.[row, 3] = self.[row, 3], self.[row, 0]
      self.[row, 1], self.[row, 2] = self.[row, 2], self.[row, 1]
    end
  end

  def reflect_vertical!
    0.upto(3) do |col|
      self.[0, col], self.[3, col] = self.[3, col], self.[0, col]
      self.[1, col], self.[2, col] = self.[2, col], self.[1, col]
    end
  end

  def rotate_right!
    transpose!
    reflect_horizonal!
  end

  def rotate_left!
    transpose!
    reflect_vertical!
  end

  def move!(opcode)
    case opcode
    when 0
      move_up!
    when 1
      move_right!
    when 2
      move_down!
    when 3
      move_left!
    else
      -1
    end
  end

  def can_move?(opcode)
    case opcode
    when 0
      can_move_up?
    when 1
      can_move_right?
    when 2
      can_move_down?
    when 3
      can_move_left?
    else
      false
    end
  end

  def to_s(io)
    @board.each_with_index do |tile, idx|
      io << tile
      io << (idx & 3) == 3 ? '\n' : '\t'
    end
  end

  def to_slice
    @board.to_slice
  end

  def move_left!
    score = 0

    4.times do |r|
      i = 0

      1.upto(3) do |j|
        next if self[r, j] == 0

        if self[r, i] != 0
          while (i + 1) < j && self[r, i + 1] != 0
            i += 1
          end

          if self[r, i] == self[r, j]
            self[r, i] += 1
            self[r, j] = 0
            score += TILE_MAPPING[self[r, i]]
            i += 1
          elsif self[r, i + 1] == 0
            i += 1
            self[r, i], self[r, j] = self[r, j], 0
          end
        else
          self[r, i], self[r, j] = self[r, j], 0
        end
      end
    end

    score
  end

  def move_right!
    reflect_horizonal!
    score = move_left!
    reflect_horizonal!
    score
  end

  def move_up!
    transpose!
    score = move_left!
    transpose!
    score
  end

  def move_down!
    transpose2!
    score = move_left!
    transpose2!
    score
  end

  def can_move_left?
    4.times do |r|
      1.upto(3) do |j|
        if self[r, j - 1] == 0 || (self[r, j - 1] == self[r, j])
          return true
        end
      end
    end
    false
  end

  def can_move_right?
    reflect_horizonal!
    can = can_move_left?
    reflect_horizonal!
    can
  end

  def can_move_up?
    transpose!
    can = can_move_left?
    transpose!
    can
  end

  def can_move_down?
    transpose2!
    can = can_move_left?
    transpose2!
    can
  end

  def clear
    @board.[] = 0
  end

  def each
    @board.each
  end
end
