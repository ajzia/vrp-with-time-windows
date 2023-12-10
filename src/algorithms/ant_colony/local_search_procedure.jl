function is_feasible(
  route::Vector{Int},
  customers::Vector{Customer},
  service_start::Function,
  vehicle_capacity::Int,
)::Bool
  # load of the path
  if sum([customers[i+1].demand for i in route]) > vehicle_capacity
    return false
  end

  # check if begin times of customers are before their due times
  # this check also includes return the depot
  b_i::Float64 = 0.0
  for idx in 2:length(route)
    b_j::Float64 = service_start(
      route[idx-1] + 1, route[idx] + 1, b_i
    )
    if b_j > customers[route[idx] + 1].time_window[2]
      return false
    end

    b_i = b_j
  end

  return true
end


# local search using CROSS exchanges
# https://www.researchgate.net/publication/220413375_A_Tabu_Search_Heuristic_for_the_Vehicle_Routing_Problem_with_Soft_Time_Windows
# https://www.jstor.org/stable/25768766
function local_search(
  path::Vector{Int},
  path_cost::Float64,
  start_route::Int,
  customers::Vector{Customer},
  distances::Array{Float64, 2},
  service_start::Function,
  vehicle_capacity::Int,
)::Tuple{Vector{Int}, Float64, Int}

  routes::Vector{Vector{Int}} = route_to_routes(path)
  no_routes::Int = length(routes)

  for i in start_route:no_routes-1, j in i+1:no_routes # for each pair of routes
    first::Vector{Int} = routes[i]
    second::Vector{Int} = routes[j]

     # for each pair of starting customers
    for x1_idx in 1:length(first[1:end-1]), x2_idx in 1:length(second[1:end-1])
      # for each pair of ending customers
      for y1_idx in 1:length(first[x1_idx:end-1]), y2_idx in 1:length(second[x2_idx:end-1])
        first_path::Vector{Int} = vcat(
          first[1:x1_idx], second[x2_idx+1:y2_idx], first[y1_idx+1:end]
        )
        second_path::Vector{Int} = vcat(
          second[1:x2_idx], first[x1_idx+1:y1_idx], second[y2_idx+1:end]
        )

        is_feasible(
          first_path,
          customers,
          service_start,
          vehicle_capacity,
        ) || continue

        is_feasible(
          second_path,
          customers,
          service_start,
          vehicle_capacity,
        ) || continue
        
        new_routes::Vector{Vector{Int}} = deepcopy(routes)
        new_routes[i] = first_path
        new_routes[j] = second_path

        new_route_cost::Float64 = route_cost(
          routes_to_route(new_routes), distances)

        if new_route_cost < path_cost
          routes[i] = first_path
          routes[j] = second_path
          
          return (routes_to_route(routes), new_route_cost, i)
        end
      end # for_3
    end # for_2
  end # for_1
  
  return ([], typemax(Float64), 0)
end


function local_search_procedure(
  ant::Ant,
  customers::Vector{Customer},
  distances::Array{Float64, 2},
  service_start::Function,
  vehicle_capacity::Int,
)
  new_path::Vector{Int} = deepcopy(ant.path)
  new_cost::Float64 = ant.cost

  max_search::Int = 50
  iterations::Int = 0
  start_route::Int = 1

  # runs until there is no improvement
  # or until max_search is reached
  while iterations < max_search
    temp_path, temp_cost, temp_cust = local_search(
      new_path,
      new_cost,
      start_route,
      customers,
      distances,
      service_start,
      vehicle_capacity,
    )

    if !isempty(temp_path)
      iterations += 1

      new_path = temp_path
      new_cost = round(temp_cost, digits=2)

      no_depots::Int = count(x -> x == 0, new_path)
      start_route = (temp_cust + 1) % (no_depots - 1)
      start_route = max(start_route, 1)
    else # there was no improvement
      break
    end
  end # while

  ant.path = new_path
  ant.cost = round(new_cost, digits=2)
end
