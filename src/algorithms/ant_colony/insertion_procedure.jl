# insertion based on Solomon Sequential Insertion I1 Algorithm
function insertion_procedure(
  ant::Ant,
  customers::Vector{Customer},
  distances::Array{Float64, 2},
  service_start::Function,
  vehicle_capacity::Int,
)
  if isempty(ant.unrouted_customers)
    return
  end

  routes::Vector{Vector{Int}} = route_to_routes(ant.path)
  no_routes::Int = length(routes)

  # loads for all the routes in path
  route_loads::Vector{Int} = zeros(Int, no_routes)
  for (index, route) in enumerate(routes)
    for cust_id in route[2:end-1]
      route_loads[index] += customers[cust_id+1].demand
    end
  end

  # begin times for all the routes in path
  route_begin_times::Vector{Vector{Float64}} = []
  for (index, route) in enumerate(routes)
    push!(route_begin_times, [0.])
    for (i, cust_id) in enumerate(route[1:end-1])
      b_i::Float64 = route_begin_times[index][i]
      b_j::Float64 = service_start(
        cust_id + 1, route[i+1] + 1, b_i
      )

      push!(route_begin_times[index], b_j)
    end
  end
  
  # sorting customers by their demands in the descending order
  sorted_customers::Vector{Customer} =
    [customers[i] for i in ant.unrouted_customers]

  sort!(
    sorted_customers,
    by = customer -> customer.demand,
    rev = true
  )

  for customer in sorted_customers
    # find best place of insertion for each route
    best_places::Vector{Int} = zeros(Int, no_routes)
    for (i, route) in enumerate(routes)
      if route_loads[i] + customer.demand > vehicle_capacity
        best_places[i] = -1
        continue
      end

      ins_place_idx::Float64 = find_best_insertion_places(
        customers,
        [customer.id+1],
        route,
        route_begin_times[i],
        distances,
        service_start
      )[1]

      best_places[i] = ins_place_idx
    end

    # if no route can accommodate the customer, there is
    # no point in inserting next customers,
    # since the solution will be infeasible
    if (best_places .== -1) |> any
      ant.path = routes_to_route(routes)
      return
    end

    # find best route for insertion
    best_cost::Float64 = Inf
    best_route::Int = -1
    for (i, ins_place_idx) in enumerate(best_places)
      if ins_place_idx == -1
        continue
      end

      insertion_cost::Float64 = c2(
        routes[i][ins_place_idx] + 1,
        customer.id + 1,
        routes[i][ins_place_idx + 1] + 1,
        service_start,
        distances,
        route_begin_times[i][ins_place_idx],
        route_begin_times[i][ins_place_idx + 1]
      )

      if insertion_cost < best_cost
        best_cost = insertion_cost
        best_route = i
      end
    end

    if best_route == -1
      continue
    end


    # update route loads & cost
    ins_place::Int = best_places[best_route]
    route::Vector{Int} = routes[best_route]
    route_loads[best_route] += customer.demand

    # insert customer into the best route
    insert!(routes[best_route], ins_place + 1, customer.id)

    # because of errors due to floating point arithmetic
    # we need to calculate length of the whole route
    # rather than updating it
    ant.cost = route_cost(routes_to_route(routes), distances)

    filter!(x -> x != (customer.id + 1), ant.unrouted_customers)

    # update begin times
    route_begin_times[best_route] = [0.]
    for (i, cust_id) in enumerate(routes[best_route][1:end-1])
      b_i::Float64 = route_begin_times[best_route][i]
      b_j::Float64 = service_start(
        cust_id + 1, routes[best_route][i+1] + 1, b_i
      )

      push!(route_begin_times[best_route], b_j)
    end
  end # for customer in sorted_customers

  ant.path = routes_to_route(routes)
end
