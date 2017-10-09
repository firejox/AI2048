require "./approx_func"
require "./board"

class Synapse
  property weight = 0.0
  property prev_weight = 0.0
  property src_neuron : Neuron
  property dest_neuron : Neuron

  def initialize(@src_neuron, @dest_neuron)
  end
end

class Neuron
  property synapses_in = [] of Synapse
  property synapses_out = [] of Synapse

  property threshold = 0.0
  property prev_threshold = 0.0
  property output = 0.0
  property error = 0.0

  def calculate_output
    activation = @synapses_in.sum(-@threshold) do |synapse|
      synapse.src_neuron.output * synapse.weight
    end

    @output = Math.max(0.0, activation)
    @error = activation > -1e4 ? 1.0 : 0.0
  end

  def train(rate, target)
    @error *= (target - @output)
    update_weights(rate)
  end

  def train(rate)
    @error *= @synapses_out.sum do |synapse|
      synapse.prev_weight * synapse.dest_neuron.error
    end

    update_weights(rate)
  end

  def update_weights(rate)
    @synapses_in.each do |synapse|
      synapse.prev_weight = synapse.weight
      synapse.weight = synapse.weight * (1.0 - rate) + rate * @error * synapse.src_neuron.output
    end

    @prev_threshold = @threshold
    @threshold = @threshold * (rate - 1.0) - rate * @error
  end
end

abstract class NeuralNetwork
  include ApproxFunc

  abstract def tuning(by targets)
end
