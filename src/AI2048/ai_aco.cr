require "./agent"
require "./deep_net"

struct Ant
  getter path : Array(Action)
  property score = 0

  def initialize
    @path = [] of Action
  end

  def save_action(action)
    @path << action
  end
end

class AIACO < Agent
  EVAPORATION_RATE = 0.3
  DECAY_RATE = 0.3
  EXPLOITATION_RATE = 0.9

  property engine
  @pheromon_map : DeepNetwork
  @elite_ant : Ant
  @cur_ant : Ant
  @ant_num : Int32

  def initialize(args : String)
    super("name=ai_aco " + args)

    @engine = Random.new
    @elite_ant = Ant.new
    @cur_ant = Ant.new

    @ant_num = @prop["ant_num"].to_i
    @count = @ant_num

    @pheromon_map = DeepNetwork.new
    @pheromon_map.update_parameters { @engine.rand(1e-4) }
  end

  def save_action(action)
    @cur_ant.save_action action
  end

  def update_pheromons(score)
    @count -= 1

    @cur_ant.score = score
    if @cur_ant.score > @elite_ant.score
      @cur_ant, @elite_ant = @elite_ant, @cur_ant
    end

    @cur_ant.path.clear
    @cur_ant.score = 0

    return if @count > 0
    
    @count = @ant_num

    delta = Math.log2(@elite_ant.score)

    @pheromon_map.output_layer.each do |neuron|
      neuron.synapses_in.each do |synapse|
        synapse.weight *= (1.0 - EVAPORATION_RATE)
      end
    end

    iter = @elite_ant.path.each
    board = Board.new
    iter.next.as(Action).apply!(pointerof(board))
    iter.next.as(Action).apply!(pointerof(board))

    loop do
      a = iter.next
      unless a.is_a?(Iterator::Stop)
        action = a.as(Action)
        action.apply!(pointerof(board))
        
        ph = @pheromon_map.eval(board.to_slice)[0]
        @pheromon_map.tuning by: StaticArray[(delta + ph)]

        a = iter.next
      end

      break if a.is_a?(Iterator::Stop)

      a.as(Action).apply!(pointerof(board))
    end
    @elite_ant.score = 0
  end

  def take_action(b : Board)
    branch_probs = StaticArray(Float64, 4).new(0.0)
    4.times do |op|
      if b.can_move?(op)
        tmp = b
        score = Math.max(tmp.move!(op), 1)
        branch_probs[op] = Math.max(@pheromon_map.eval(tmp.to_slice)[0], 1.0)
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

      val = @pheromon_map.eval(b.to_slice)[0]
      @pheromon_map.tuning by: StaticArray[val * (1.0 - DECAY_RATE) + DECAY_RATE * 1.0]

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
      val = @pheromon_map.eval(b.to_slice)[0]
      @pheromon_map.tuning by: StaticArray[val * (1.0 - DECAY_RATE) + DECAY_RATE * 1.0]

      Action.new move_op: op
    end
  end 
end
