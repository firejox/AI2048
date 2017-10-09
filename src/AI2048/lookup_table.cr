require "./board"

class LookUpTable

  @n_tuples : StaticArray(StaticArray(Float64, 50625), 17)

  def initialize
    @n_tuples = StaticArray(StaticArray(Float64, 50625), 17).new(StaticArray(Float64, 50625).new(0.0))
  end

  def each(b)
    4.times do |i|
      pos = b[i * 4]
      pos = pos * 15 + b[i * 4 + 1]
      pos = pos * 15 + b[i * 4 + 2]
      pos = pos * 15 + b[i * 4 + 3]
      yield @n_tuples[i][pos]
    end

    4.times do |i|
      pos = b[i]
      pos = pos * 15 + b[i + 4]
      pos = pos * 15 + b[i + 8]
      pos = pos * 15 + b[i + 12]
      yield @n_tuples[4 + i][pos]
    end

    3.times do |x|
      3.times do |y|
        pos = b[x * 4 + y] 
        pos = pos * 15 + b[x * 4 + y + 1]
        pos = pos * 15 + b[x * 4 + y + 4]
        pos = pos * 15 + b[x * 4 + y + 5]
        yield @n_tuples[8 + x * 3 + y][pos]
      end
    end
  end

  def map!(b)
    4.times do |i|
      pos = b[i * 4]
      pos = pos * 15 + b[i * 4 + 1]
      pos = pos * 15 + b[i * 4 + 2]
      pos = pos * 15 + b[i * 4 + 3]
      @n_tuples[i][pos] = yield @n_tuples[i][pos]
    end

    4.times do |i|
      pos = b[i]
      pos = pos * 15 + b[i + 4]
      pos = pos * 15 + b[i + 8]
      pos = pos * 15 + b[i + 12]
      @n_tuples[4 + i][pos] = yield @n_tuples[4 + i][pos]
    end

    3.times do |x|
      3.times do |y|
        pos = b[x * 4 + y] 
        pos = pos * 15 + b[x * 4 + y + 1]
        pos = pos * 15 + b[x * 4 + y + 4]
        pos = pos * 15 + b[x * 4 + y + 5]
        @n_tuples[8 + x * 3 + y][pos] = yield @n_tuples[8 + x * 3 + y][pos]
      end
    end
  end


  def eval(b)
    total = 0.0
    each(b) { |x| total += x }
    total
  end

  def tuning(b, by target, rate)
    output = eval(b)

    delta = (target - output) * rate / 17.0

    map!(b) { |x| x + delta }
  end
end
