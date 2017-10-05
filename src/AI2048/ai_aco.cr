require "./agent"
require "./deep_net"

class Ant
  DECAY_RATE = 0.2

  getter path : Array(Action)
  @score = 0
  @pheronmon_map : DeepNetwork


  def save_action(action)
    @path << action
  end

end

class AIACO < Agent
  EVAPORATION_RATE = 0.3

  property engine
  @pheromon_map : DeepNetwork
  @ant_path : Array(Action)

  def initialize(args : String)
    super("name=ai_aco " + args)

    @engine = Random.new
    @ant_path = [] of Action

    @pheromon_map = DeepNetwork.new
    @pheromon_map.update_parameters do
      @engine.rand(1e-4)
    end
  end

  def save_action(action)
    @ant_path << action
  end

  def update_pheromons(score)
    delta = Math.log2(score)

    @pheromon_map.output_layer.each do |neuron|
      neuron.synapses_in.each do |synapse|
        synapse.weight *= (1.0 - EVAPORATION_RATE)
      end
    end

    iter = @ant_path.each
    board = Board.new
    iter.next.as(Action).apply!(board)
    iter.next.as(Action).apply!(board)

    loop do
      a = iter.next
      unless a.is_a?(Iterator::Stop)
        action = a.as(Action)
        ph = @pheromon_map.eval(board.each.chain(Iterator.of(action.to_i)))[0]
        @pheromon_map.tuning by: StaticArray[(delta + ph)]
        action.apply!(board)

        a = iter.next
      end

      break if a.is_a?(Iterator::Stop)

      a.as(Action).apply!(board)
    end
    @ant_path.clear
  end

  def take_action(b : Board)
    branch_probs = StaticArray(Float64, 4).new(0.0)
    4.times do |op|
      if b.can_move?(op)
        branch_probs[op] = Math.max(@pheromon_map.eval(b.each.chain(Iterator.of(op)))[0], 1.0)
      end
    end

    (1..3).each do |i|
      branch_probs[i] += branch_probs[i - 1]
    end

    return Action.new if branch_probs[3] == 0.0

    val = @engine.rand(branch_probs[3])
    4.times do |op|
      if val <= branch_probs[op]
        return Action.new move_op: op
      end
    end
    Action.new
  end 
end
