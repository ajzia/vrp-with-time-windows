const selections::Dict = Dict(
  "r" => stochastic_acceptance,
  "t" => tournament,
)

const stop_conditions::Dict = Dict(
  "max_it"   => maximum_iterations,
  "no_imp"   => maximum_iterations_with_no_improvement,
  "max_time" => maximum_time,
)

"""
    generate_results(args::Vector{String})

  Generate results for a given set of parameters
  and saves them in a JSON file.
"""
function generate_results(args::Vector{String})
  if length(args) < 9
    return
  end

  if args[1] == "S"
    path = "../../resources/Solomon/"
  elseif args[1] == "H"
    path = "../../resources/Homberger/"
  else
    return
  end

  test_instances::Vector{String} = split(args[2], ",")

  if args[3] ∉ keys(stop_conditions)
    return
  end
  stop_condition = stop_conditions[args[3]]

  max_value::Int = parse(Int, args[4])

  population_size::Int = parse(Int, args[5])

  q_0::Float64 = parse(Float64, args[6])
  rho::Float64 = parse(Float64, args[7])

  if args[8] ∉ keys(selections)
    return
  end
  selection = selections[args[8]]

  results::Dict = Dict()
  results["parameters"] = Dict(
    "stop_condition" => args[3],
    "max_stop" => max_value,
    "population_size" => population_size,
    "q_0" => q_0,
    "selection" => args[8],
    "rho" => rho,
  )

  println("Parameters:")
  println(results)
  println()

  no_customers::Int = 0

  for file in test_instances
    println("> Starting ", file)
    results[file] = Dict()
    instance = read_instance(path * file * ".txt")
    if !startswith(file, "C1")
      println("Started reducing time windows...")
      instance = reduce_instance_windows(instance)
      println("Window reduced")
    end
    no_customers = length(instance.customers)-1


    nn_cost, nn_routes = nearest_neighbour(instance)
    no_vehicles::Int = length(nn_routes)
    results[file]["nn_cost"] = nn_cost
    results[file]["nn_no_vehicles"] = no_vehicles

    if population_size == 0
      population_size = no_vehicles
    end

    if length(test_instances) > 1
      name = "multiple"
    else
      name = test_instances[1]
    end

    repeat::Int = parse(Int, args[9])
    avg_cost::Float64 = 0.0
    avg_no_vehicles::Float64 = 0.0
    for it in 1:repeat
      println("    Iteration: ", it)
      acs_cost, acs_routes = ant_colony_system(
        instance,
        (nn_cost, nn_routes),
        (stop_condition,max_value),
        selection,
        no_ants = population_size,
        q_0 = q_0,
        rho = rho
      )
      avg_cost += acs_cost
      avg_no_vehicles += length(acs_routes)
    end

    results[file]["acs_cost"] = round(avg_cost / repeat, digits=2)
    results[file]["acs_no_vehicles"] = round(avg_no_vehicles / repeat, digits=2)
    results[file]["no_cust"] = no_customers
    
    println("\n")
    dict_to_json(name, no_customers, results)
  end
end
