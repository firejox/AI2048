require "./agent"
require "./lookup_table"

class AITD < Agent
  LEARNING_RATE = 0.001

  @state_func : LookUpTable
  def initialize(args : String)
    super("name=aitd " + args)
    @state_func = LookUpTable.new
  end

  def take_action(b : Board)
    opcode = -1
    val = -1.0
    4.times do |op|
      if b.can_move?(op)
        op_r = evaluate(b, op)
        if val < op_r
          val = op_r
          opcode = op
        end
      end
    end
    Action.new move_op: opcode
  end

  def learning(s1, a, r, s2, s3)
    v1 = @state_func.eval s1
    v3 = @state_func.eval s3
    @state_func.tuning s1, (r + v3), LEARNING_RATE
  end

  def evaluate(b : Board, op)
    r = b.move!(op)
    expect = 0
    count = 0
    16.times do |i|
      if b[i] == 0
        b[i] = 1
        expect += POP_TILE_WITH_ONE_RATE * @state_func.eval b.to_slice
        b[i] = 2
        expect += (1.0 - POP_TILE_WITH_TWO_RATE) * @state_func.eval b.to_slice
        b[i] = 0
        count += 1
      end
    end

    r + expect.to_f / count
  end
end
