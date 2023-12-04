module Algorithms
  include("../instances/types.jl")
  export Instance, Customer

  include("./sequential_insertion.jl")
  export sequential_insertion

  include("./nearest_neighbour.jl")
  export nearest_neighbour

  include("./ant_colony/ant.jl")
  include("./ant_colony/selection.jl")
  export roulette_wheel,
         stochastic_acceptance,
         tournament

  include("./ant_colony/stop_condition.jl")
  export maximum_iterations_with_no_improvement,
         maximum_iterations,
         maximum_time

  include("./ant_colony/insertion_procedure.jl")
  include("./ant_colony/local_search_procedure.jl")
  include("./ant_colony/ant_colony_system.jl")
  export ant_colony_system
end
