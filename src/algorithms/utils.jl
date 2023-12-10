"""
    service_begin_time(customers::Vector{Customer}, distances::Array{Float64, 2})
  
  Returns a function that calculates service begin time for a customer.
"""
function service_begin_time(
  customers::Vector{Customer},
  distances::Array{Float64, 2},
)::Function
  @inline function service_start(
    i_index::Int, j_index::Int, b_i::Float64
  )::Float64
    return max(
      customers[j_index].time_window[1],
      b_i + customers[i_index].service_time + distances[i_index, j_index]
    )
  end

  return service_start 
end


"""
    waiting_time(
      i_route_index::Int,
      j_route_index::Int,
      vehicle_route::Vector{Int},
      begin_times::Vector{Float64},
      customers::Vector{Customer},
      distances::Array{Float64, 2},
    )
  
  Caclulates waiting time at customer `j_route_index`
  coming from customer `i_route_index`. - time before
  service can start at customer `j_route_index`.
"""
@inline function waiting_time(
  i_route_index::Int,
  j_route_index::Int,
  vehicle_route::Vector{Int},
  begin_times::Vector{Float64},
  customers::Vector{Customer},
  distances::Array{Float64, 2},
)::Float64
  customer_i::Customer = customers[vehicle_route[i_route_index] + 1]
  j_arrival_time::Float64  = (
    begin_times[i_route_index]
    + customer_i.service_time
    + distances[vehicle_route[i_route_index] + 1, vehicle_route[j_route_index] + 1]
  )

  return begin_times[j_route_index] - j_arrival_time
end


@inline function route_cost(
  route::Vector{Int},
  distances::Array{Float64, 2},
)::Float64
  cost::Float64 = 0.0
  for i in 1:length(route)-1
    cost += distances[route[i] + 1, route[i+1] + 1]
  end

  return cost
end


@inline function route_to_routes(
  route::Vector{Int}
)::Vector{Vector{Int}}
  depot_id::Int = route[1]
  routes::Vector{Vector{Int}} = [[depot_id]]

  counter::Int = 1
  for i in 2:length(route)-1
    push!(routes[counter], route[i])
    if route[i] == depot_id
      counter += 1
      push!(routes, [depot_id])
    end
  end

  push!(routes[counter], depot_id)

  return routes
end


@inline function routes_to_route(
  routes::Vector{Vector{Int}}
)::Vector{Int}
  depot_id::Int = routes[1][1]

  route::Vector{Int} = []
  for tour in routes
    route = vcat(route, tour[1:end-1])
  end

  push!(route, depot_id)

  return route
end
