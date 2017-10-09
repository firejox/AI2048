require "./board"

class LookUpTable
  def initialize(value = 0.0)
    @n_tuples = uninitialized StaticArray(Float64, 860625)
    @n_tuples.map! { value }
  end

  def each(b)
    4.times do |i|
      pos = b[i * 4]
      pos = pos * 15 + b[i * 4 + 1]
      pos = pos * 15 + b[i * 4 + 2]
      pos = pos * 15 + b[i * 4 + 3]
      yield @n_tuples[i * 50625 + pos]
    end

    4.times do |i|
      pos = b[i]
      pos = pos * 15 + b[i + 4]
      pos = pos * 15 + b[i + 8]
      pos = pos * 15 + b[i + 12]
      yield @n_tuples[(4 + i) * 50625 + pos]
    end

    3.times do |x|
      3.times do |y|
        pos = b[x * 4 + y]
        pos = pos * 15 + b[x * 4 + y + 1]
        pos = pos * 15 + b[x * 4 + y + 4]
        pos = pos * 15 + b[x * 4 + y + 5]
        yield @n_tuples[(8 + x * 3 + y) * 50625 + pos]
      end
    end
  end

  def map!(b)
    4.times do |i|
      pos = b[i * 4]
      pos = pos * 15 + b[i * 4 + 1]
      pos = pos * 15 + b[i * 4 + 2]
      pos = pos * 15 + b[i * 4 + 3]
      @n_tuples[i * 50625 + pos] = yield @n_tuples[i * 50625 + pos]
    end

    4.times do |i|
      pos = b[i]
      pos = pos * 15 + b[i + 4]
      pos = pos * 15 + b[i + 8]
      pos = pos * 15 + b[i + 12]
      @n_tuples[(4 + i) * 50625 + pos] = yield @n_tuples[(4 + i) * 50625 + pos]
    end

    3.times do |x|
      3.times do |y|
        pos = b[x * 4 + y]
        pos = pos * 15 + b[x * 4 + y + 1]
        pos = pos * 15 + b[x * 4 + y + 4]
        pos = pos * 15 + b[x * 4 + y + 5]
        @n_tuples[(8 + x * 3 + y) * 50625 + pos] = yield @n_tuples[(8 + x * 3 + y) * 50625 + pos]
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

  def to_slice
    @n_tuples.to_slice
  end
end
