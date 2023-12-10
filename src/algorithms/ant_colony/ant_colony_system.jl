function new_active_ant(
  ant::Ant,
  instance::Instance,
  customers::Vector{Customer},
  distances::Array{Float64, 2},
  pheromones::Array{Float64, 2}, # global pheromone matrix
  selection::Function,
  tau::Float64,  # initial pheromone value
  rho::Float64,  # pheromone evaporation rate
  beta::Float64, # importance of attractiveness
  q_0::Float64,  # probabilty of choosing the best customer
)
  # instance data
  vehicle_capacity::Int = instance.q
  service_start::Function = service_begin_time(customers, distances)
  
  # ant initialization
  ant_time::Float64 = 0.0
  ant_load::Int = 0

  # local pheromone update
  @inline local_pheromone_update(curr_idx::Int, cust_idx::Int) =
    pheromones[curr_idx, cust_idx] = (
      (1 - rho) * pheromones[curr_idx, cust_idx] + rho * tau
    )
  
  # route construction
  # check if there are unrouted customers and unused depots
  while !isempty(ant.unrouted_customers) && ant.unused_depots > 0
    possible_customers::Vector{Int} = get_possible_customers(
      ant,
      ant_load,
      ant_time,
      customers,
      vehicle_capacity,
      service_start
    )

    if isempty(possible_customers) && ant.unused_depots > 0
      push!(ant.path, ant.path[1])
      local_pheromone_update(ant.curr_idx, 1)

      ant.cost += distances[ant.curr_idx, 1]
      ant.curr_idx = 1 # depot index
      ant.unused_depots -= 1

      ant_load = 0
      ant_time = 0.0
      continue
    end

    # calculate attractiveness and probability of choosing customers
    attractiveness::Vector{Float64} = []
    choice_probabilty::Vector{Float64} = []
    for customer_idx in possible_customers
      eta = calculate_attractiveness(
        ant, ant_time,
        customer_idx, customers,
        distances
      )
      push!(attractiveness, eta)
      push!(choice_probabilty, 
        pheromones[ant.curr_idx, customer_idx] * (eta ^ beta)
      )
    end
    
    attractiveness_sum = sum(choice_probabilty)
    map!(x -> x / attractiveness_sum, choice_probabilty, choice_probabilty)


    # selecting customer
    cust_idx::Int = 0
    if rand() < q_0 # exploitation
      # get index of customer for which choice probability is max
      index = argmax(choice_probabilty)
      cust_idx = possible_customers[index]
    else # exploration
      # choosing customers based on selection
      index = selection(choice_probabilty)
      cust_idx = possible_customers[index]
    end

    # update ant's path
    chosen_customer::Customer = customers[cust_idx]
    push!(ant.path, chosen_customer.id)
    filter!(x -> x != cust_idx, ant.unrouted_customers)

    # update ant's statistics
    ant.cost += distances[ant.curr_idx, cust_idx]
    ant_time = service_start(ant.curr_idx, cust_idx, ant_time)
    ant_load += chosen_customer.demand

    local_pheromone_update(ant.curr_idx, cust_idx)

    ant.curr_idx = cust_idx
  end # while

  if isempty(ant.unrouted_customers)
    push!(ant.path, ant.path[1])
    local_pheromone_update(ant.curr_idx, 1)

    ant.cost += distances[ant.curr_idx, 1]
    ant.unused_depots -= 1

    ant.curr_idx = 1
  end

  # inserting unrouted customers into ant's path
  insertion_procedure(
    ant,
    customers,
    distances,
    service_start,
    vehicle_capacity,
  )

  # local search procedure
  if isempty(ant.unrouted_customers)
    local_search_procedure(
      ant,
      customers,
      distances,
      service_start,
      vehicle_capacity,
    )
  end

  ant.cost = round(ant.cost, digits=2)
  return
end # new_active_ant


function ant_colony_system(
  instance::Instance,
  initial_solution::Tuple{Float64, Vector{Vector{Int}}},
  stop_condition::Tuple{Function, Int},
  selection::Function;
  no_ants::Int = length(initial_solution[2]),
  q_0::Float64 = 0.4, # probabilty of choosing the best customer
  tau::Float64 = 1 / (length(instance.customers) * initial_solution[1]), # initial pheromone value
  rho::Float64 = 0.7, # pheromone evaporation rate
  beta::Float64 = 1., # importance of attractiveness
)::Tuple{Float64, Vector{Vector{Int}}}
  best_cost::Float64, best_solution::Vector{Vector{Int}} = initial_solution

  no_vehicles_used::Int = length(initial_solution[2])
  no_customers::Int = length(instance.customers)
  customers::Vector{Customer} = copy(instance.customers)
  distances::Array{Float64, 2} = copy(instance.distances)

  # pheromone initialization
  pheromones::Array{Float64, 2} = fill(tau, (no_customers, no_customers))

  # stop condition initialization
  (stop_function, max) = stop_condition
  start, max, increment, check_stop = stop_function(max)

  # main loop
  while check_stop(start) # stops when stop_condition is met
    ants::Vector{Ant} = [
      Ant(0., [0], 1, no_vehicles_used, collect(2:no_customers))
      for _ in 1:no_ants
    ]

    for k in 1:no_ants
      new_active_ant(
        ants[k],
        instance,
        customers,
        distances,
        pheromones,
        selection,
        tau,
        rho,
        beta,
        q_0,
      )
    end


    # check if ant's solution is feasible
    ant_costs::Vector{Float64} = []
    for k in 1:no_ants
      if !isempty(ants[k].unrouted_customers)
        push!(ant_costs, typemax(Float64))
      else
        push!(ant_costs, ants[k].cost)
      end
    end
    
    best_ant::Int = argmin(ant_costs)
    if ant_costs[best_ant] < best_cost
      best_solution = route_to_routes(ants[best_ant].path)
      best_cost = ant_costs[best_ant]
      start = increment(start, true)
    end


    # global pheromone update
    for (_, route) in enumerate(best_solution)
      for index in 1:length(route)-1
        i::Int = route[index] + 1
        j::Int = route[index+1] + 1
        pheromones[i, j] = (1 - rho) * pheromones[i, j] + rho / best_cost
      end
    end

    start = increment(start, false)
  end # while

  return best_cost, best_solution
end # ant_colony_system
