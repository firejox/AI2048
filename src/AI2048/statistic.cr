require "./agent"
require "./action"
require "./board"
require "./helper"

class Statistic
  property data

  def initialize(@total : Int32, @block = 0)
    @block = @block != 0 ? @block : @total
    @data = [] of Record
  end

  def show
    block = Math.min(@data.size, @block)
    sum, max, opc, duration = 0, 0, 0, 0
    stat = {{ "StaticArray(Int32, #{TILE_MAPPING.args.size}).new(0)".id }}
    iter = @data.reverse_each

    block.times do |i|
      path = iter.next.as(Record)
      game = Board.new
      score = path.actions.sum { |action| action.apply!(pointerof(game)) }
      sum += score
      max = Math.max(score, max)
      opc += (path.actions.size - 2) / 2
      tile = 0
      0.upto(15) do |t|
        tile = Math.max(tile, game[t])
      end
      stat[tile] += 1
      duration += path.tock_time - path.tick_time
    end

    avg = sum.to_f / block
    coef = 100.0 / block
    ops = opc * 1000.0 / duration
    puts "%d\tavg = %d, max = %d, ops = %d" % [@data.size, avg.to_i, max.to_i, ops.to_i]

    t, c = 0, 0
    while c < block
      # to be fixed
      if stat[t] == 0
        c += stat[t]
        t += 1
        next
      end
      accu = stat.each.skip(t).sum
      puts "\t%d\t%.2f%%\t(%.2f%%)" % [TILE_MAPPING[t], accu * coef, stat[t] * coef]
      c += stat[t]
      t += 1
    end
    puts ""
  end

  def is_finished
    @data.size >= @total
  end

  def run_until_finished
    @total.times do
      with self yield
    end
  end

  def open_episode(&block)
    @data << Record.new
    @data[-1].tick

    yield

    @data[-1].tock

    if @data.size % @block == 0
      show
      @data.clear
    end
  end

  def save_action(move : Action)
    @data[-1].actions << move
  end

  def take_turns(player : Agent, evil : Agent)
    (max(@data[-1].actions.size + 1, 2) % 2 == 1) ? player : evil
  end

  def last_turns(player : Agent, evil : Agent)
    take_turns(evil, player)
  end

  def log(file : File)
    file.write_bytes(@data.size.to_u64, IO::ByteFormat::LittleEndian)
    @data.each do |rec|
      rec.log(file)
    end
  end

  class Record
    property actions
    getter tick_time
    getter tock_time

    def initialize
      @actions = Array(Action).new 32768
      @tick_time = 0_i64
      @tock_time = 0_i64
    end

    @[AlwaysInline]
    def tick
      @tick_time = Time.new.epoch_ms
    end

    @[AlwaysInline]
    def tock
      @tock_time = Time.new.epoch_ms
    end

    def log(file : File)
      file.write_bytes(@actions.size.to_u64, IO::ByteFormat::LittleEndian)
      @actions.each do |action|
        file.write_bytes(action.to_i.to_u16, IO::ByteFormat::LittleEndian)
      end
      file.write_bytes(@tick_time, IO::ByteFormat::LittleEndian)
      file.write_bytes(@tock_time, IO::ByteFormat::LittleEndian)
    end
  end
end
