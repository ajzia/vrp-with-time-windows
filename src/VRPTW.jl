module VRPTW
  using Reexport
  include("./algorithms/algorithms.jl")
  @reexport using .Algorithms

  include("generate_results.jl")
  export generate_results
end
