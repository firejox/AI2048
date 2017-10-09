require "./neural_net"

class DeepNetwork < NeuralNetwork
  getter input_layer : StaticArray(Neuron, 16)
  getter hidden_layers : StaticArray(StaticArray(Neuron, 16), 9)
  getter output_layer : StaticArray(Neuron, 1)

  def initialize
    @input_layer = StaticArray(Neuron, 16).new { Neuron.new }
    @output_layer = StaticArray(Neuron, 1).new { Neuron.new }
    @hidden_layers = StaticArray(StaticArray(Neuron, 16), 9).new { StaticArray(Neuron, 16).new { Neuron.new } }

    @input_layer.zip(@hidden_layers[0]) do |a, b|
      synapse = Synapse.new(a, b)
      b.synapses_in << synapse
      a.synapses_out << synapse
    end

    gap = 4
    (1..3).step(2) do |k|
      gap >>= 1
      4.times do |i|
        4.times do |j|
          synapse = Synapse.new(@hidden_layers[k - 1][i*4 + j], @hidden_layers[k][i*4 + j])
          @hidden_layers[k - 1][i*4 + j].synapses_out << synapse
          @hidden_layers[k][i*4 + j].synapses_in << synapse

          synapse = Synapse.new(@hidden_layers[k - 1][i*4 + j ^ gap], @hidden_layers[k][i*4 + j])

          @hidden_layers[k - 1][i*4 + j ^ gap].synapses_out << synapse
          @hidden_layers[k][i*4 + j].synapses_in << synapse

          synapse = Synapse.new(@hidden_layers[k][i*4 + j], @hidden_layers[k + 1][i*4 + j])
          @hidden_layers[k][i*4 + j].synapses_out << synapse
          @hidden_layers[k + 1][i*4 + j].synapses_in << synapse

          synapse = Synapse.new(@hidden_layers[k - 1][(i ^ gap)*4 + j], @hidden_layers[k][i*4 + j])

          @hidden_layers[k][(i ^ gap)*4 + j].synapses_out << synapse
          @hidden_layers[k + 1][i*4 + j].synapses_in << synapse
        end
      end
    end

    (5..7).step(2) do |k|
      4.times do |i|
        4.times do |j|
          synapse = Synapse.new(@hidden_layers[k - 1][i*4 + j], @hidden_layers[k][i*4 + j])
          @hidden_layers[k - 1][i*4 + j].synapses_out << synapse
          @hidden_layers[k][i*4 + j].synapses_in << synapse

          synapse = Synapse.new(@hidden_layers[k - 1][i*4 + j ^ gap], @hidden_layers[k][i*4 + j])

          @hidden_layers[k - 1][i*4 + j ^ gap].synapses_out << synapse
          @hidden_layers[k][i*4 + j].synapses_in << synapse

          synapse = Synapse.new(@hidden_layers[k][i*4 + j], @hidden_layers[k + 1][i*4 + j])
          @hidden_layers[k][i*4 + j].synapses_out << synapse
          @hidden_layers[k + 1][i*4 + j].synapses_in << synapse

          synapse = Synapse.new(@hidden_layers[k - 1][(i ^ gap)*4 + j], @hidden_layers[k][i*4 + j])

          @hidden_layers[k][(i ^ gap)*4 + j].synapses_out << synapse
          @hidden_layers[k + 1][i*4 + j].synapses_in << synapse
        end
      end
      gap <<= 1
    end

    @hidden_layers[-1].each do |a|
      @output_layer.each do |b|
        synapse = Synapse.new(a, b)
        b.synapses_in << synapse
        a.synapses_out << synapse
      end
    end
  end

  def eval(inputs)
    @input_layer.zip(inputs) do |neuron, input|
      neuron.output = input.to_f
    end

    @hidden_layers.each do |layer|
      layer.each do |neuron|
        neuron.calculate_output
      end
    end

    @output_layer.each do |neuron|
      neuron.calculate_output
    end

    @output_layer.map do |neuron|
      neuron.output
    end
  end

  def eval(inputs : Iterator)
    @input_layer.each.zip(inputs).each do |neuron, input|
      neuron.output = input.to_f
    end

    @hidden_layers.each do |layer|
      layer.each do |neuron|
        neuron.calculate_output
      end
    end

    @output_layer.each do |neuron|
      neuron.calculate_output
    end

    @output_layer.map do |neuron|
      neuron.output
    end
  end

  def update_parameters(&block)
    @hidden_layers.each do |layer|
      layer.each do |neuron|
        neuron.synapses_in.each do |synapse|
          synapse.weight = yield synapse.weight
        end
        neuron.threshold = yield neuron.threshold
      end
    end

    @output_layer.each do |neuron|
      neuron.synapses_in.each do |synapse|
        synapse.weight = yield synapse.weight
      end
      neuron.threshold = yield neuron.threshold
    end
  end

  def parameters(&block)
    @hidden_layers.each do |layer|
      layer.each do |neuron|
        neuron.synapses_in.each do |synapse|
          yield synapse.weight
        end
        yield neuron.threshold
      end
    end

    @output_layer.each do |neuron|
      neuron.synapses_in.each do |synapse|
        yield synapse.weight
      end
      yield neuron.threshold
    end
  end

  def parameter_size
    i = 0
    parameters { i += 1 }
    i
  end

  def tuning(by targets)
    @output_layer.zip(targets) do |neuron, target|
      neuron.train(0.3, target)
    end

    @hidden_layers.reverse_each do |layer|
      layer.each do |neuron|
        neuron.train(0.3)
      end
    end
  end
end
