module Algorithms
  using Reexport

  include("../instances/instances.jl")
  @reexport using .Instances

  include("./nearest_neighbour.jl")
  export find_closest_customer, nearest_neighbour

  include("./sequential_insertion.jl")
  export c1, c2, c_11, c_12
  export find_best_insertion_places
  export sequential_insertion

  include("./ant_colony/ant.jl")
  include("./ant_colony/selection.jl")
  export service_begin_time, waiting_time
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
