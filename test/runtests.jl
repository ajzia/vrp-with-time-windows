# include("../src/VRPTW.jl")
using VRPTW
using Test

@testset "VRPTW.jl" verbose = true begin
  include("./test_parsing_files.jl")

  include("./algorithms/test_nearest_neighbour.jl")
  include("./algorithms/test_sequential_insertion.jl")
end
