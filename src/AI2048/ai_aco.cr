require "./agent"
require "./lookup_table"

struct Ant
  getter path = [] of Action
  property score = 0

  def save_action(action)
    @path << action
  end

  def update_pheromon(ph_map, rate)
    delta = Math.log2(@score)

    iter = @path.each
    board = Board.new
    iter.next.as(Action).apply!(pointerof(board))
    iter.next.as(Action).apply!(pointerof(board))

    loop do
      a = iter.next
      unless a.is_a?(Iterator::Stop)
        action = a.as(Action)
        action.apply!(pointerof(board))

        ph = ph_map.eval board.to_slice
        ph_map.tuning board.to_slice, (delta * rate + ph), 1.0

        a = iter.next
      end

      break if a.is_a?(Iterator::Stop)

      a.as(Action).apply!(pointerof(board))
    end
  end
end

class AIACO < Agent
  EVAPORATION_RATE  =   0.01
  DECAY_RATE        = 0.0025
  EXPLOITATION_RATE =    0.9
  LEARNING_RATE     =   0.04

  property engine
  @pheromon_map : LookUpTable
  @desirable_map : LookUpTable
  @gbest_ant : Ant
  @ibest_ant : Ant
  @cur_ant : Ant
  @ant_num : Int32

  def initialize(args : String)
    super("name=ai_aco " + args)

    @engine = Random.new
    @gbest_ant = Ant.new
    @ibest_ant = Ant.new
    @cur_ant = Ant.new

    @ant_num = @prop["ant_num"].to_i
    @count = @ant_num

    @pheromon_map = LookUpTable.new 1.0/17.0
    @desirable_map = LookUpTable.new
  end

  def save_action(action)
    @cur_ant.save_action action
  end

  def update_pheromons(score)
    @count -= 1

    @cur_ant.score = score
    if @cur_ant.score > @ibest_ant.score
      @cur_ant, @ibest_ant = @ibest_ant, @cur_ant
      if @ibest_ant.score > @gbest_ant.score
        @gbes_ant, @ibest_ant = @ibest_ant, @gbest_ant
      end
    end

    @cur_ant.path.clear
    @cur_ant.score = 0

    return if @count > 0

    @count = @ant_num

    slice = @pheromon_map.to_slice
    slice.to_unsafe.map!(slice.size) { |w| Math.max(w * (1.0 - EVAPORATION_RATE), 1.0/17) }

    @ibest_ant.update_pheromon(@pheromon_map, EVAPORATION_RATE * 0.2)
    @gbest_ant.update_pheromon(@pheromon_map, EVAPORATION_RATE * 0.8)

    @ibest_ant.score = 0
  end

  def take_action(b : Board)
    branch_probs = StaticArray(Float64, 4).new(0.0)
    4.times do |op|
      if b.can_move?(op)
        tmp = b
        r = tmp.move!(op)
        score = Math.max(evaluate_desirable(tmp.to_slice, r), 1.0)
        branch_probs[op] = Math.max(@pheromon_map.eval(tmp.to_slice), 1.0)
        branch_probs[op] *= score**2
      end
    end

    total = branch_probs.sum

    return Action.new if total == 0.0

    branch_probs.map! { |x| x / total }

    if @engine.rand <= EXPLOITATION_RATE
      op = 0
      val = 0
      4.times do |i|
        if val < branch_probs[i]
          val = branch_probs[i]
          op = i
        end
      end

      b.move!(op)
      @pheromon_map.tuning b.to_slice, by: 1.0, rate: DECAY_RATE
      Action.new move_op: op
    else
      op = 0
      selected_prob = @engine.rand
      while true
        selected_prob -= branch_probs[op]
        break if selected_prob <= 0.0
        op += 1
      end

      b.move!(op)
      @pheromon_map.tuning b.to_slice, by: 1.0, rate: DECAY_RATE
      Action.new move_op: op
    end
  end

  def learning(s1, a, r, s2, s3)
    v1 = @desirable_map.eval s1
    v3 = @desirable_map.eval s3
    @desirable_map.tuning s1, (r + v3), LEARNING_RATE
  end

  def evaluate_desirable(b, r)
    expect = 0
    count = 0
    16.times do |i|
      if b[i] == 0
        b[i] = 1
        expect += POP_TILE_WITH_ONE_RATE * @desirable_map.eval b
        b[i] = 2
        expect += POP_TILE_WITH_TWO_RATE * @desirable_map.eval b
        b[i] = 0
        count += 1
      end
    end

    r + expect.to_f / count
  end
end
