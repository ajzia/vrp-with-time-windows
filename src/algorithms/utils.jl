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
