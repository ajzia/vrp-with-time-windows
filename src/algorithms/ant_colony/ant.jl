include("../utils.jl")

mutable struct Ant
  cost::Float64
  path::Vector{Int}
  curr_idx::Int
  unused_depots::Int
  unrouted_customers::Vector{Int} # indices
end


function get_possible_customers(
  ant::Ant,
  ant_load::Int,
  ant_time::Float64,
  customers::Vector{Customer},
  vehicle_capacity::Int,
  service_start::Function
)::Vector{Int}
  curr_idx::Int = ant.curr_idx
  possible_customers = Vector{Int}()

  for customer_idx in ant.unrouted_customers # customer's index
    curr_cust::Customer = customers[customer_idx]
    # check if customer's demand can be satisfied
    if ant_load + curr_cust.demand > vehicle_capacity
      continue
    end

    # check if begin time at customer j
    # is before its due time
    b_j::Float64 = service_start(
      curr_idx, customer_idx, ant_time
    )
    if b_j > customers[customer_idx].time_window[2]
      continue
    end
    
    # check if we can feasibly return to depot
    # after visiting customer j
    b_depot::Float64 = service_start(
      customer_idx, 1, b_j
    )
    if b_depot > customers[1].time_window[2]
      continue
    end

    push!(possible_customers, customer_idx)
  end

  return possible_customers
end


function calculate_attractiveness(
  ant::Ant,
  ant_time::Float64,
  customer_idx::Int,
  customers::Vector{Customer},
  distances::Array{Float64, 2},
)::Float64
  delivery_time::Float64 = max(
    ant_time + distances[ant.curr_idx, customer_idx],
    customers[customer_idx].time_window[1]
  )

  delta_time::Float64 = delivery_time - ant_time
  distance::Float64 =
    delta_time * (customers[customer_idx].time_window[2] - ant_time)
  distance = max(1., distance)

  return 1. / distance
end
