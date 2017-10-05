
module ApproxFunc
  abstract def eval(input)
  abstract def update_parameters(&block : Float64->Float64)
  abstract def parameters(&block : Float64->)
  abstract def parameter_size
end
