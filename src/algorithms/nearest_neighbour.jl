include("../instances/file_parser.jl")
using Reexport
@reexport using .FileParser

@inline function find_closest_customer(
  possible_customers::Vector{Int},
  begin_times::Vector{Float64},
  b_i::Float64,
  current_id::Int,
  customers::Vector{Customer},
  distances::Array{Float64, 2},
  δ1::Float64, δ2::Float64, δ3::Float64
)::Tuple{Customer, Float64}
  if δ1 < 0 || δ2 < 0 || δ3 < 0
    throw("δ1, δ2 and δ3 must be greater than or equal to 0.")
  end

  if δ1 + δ1 + δ3 != 1.0
    throw("δ1, δ2 and δ3 must sum to 1.")
  end
  # c is the metric used to evaluate possible customers
  # based on their geographical and temporal closeness
  c_min::Float64 = typemax(Float64)
  (best_customer::Int, best_time::Float64) = (0, 0.)

  for (cust, b_j) in zip(possible_customers, begin_times)
    # time difference between completion of
    # service at i and beginning service at j
    T_ij::Float64 = b_j - (b_i - customers[cust].service_time)
    v_ij::Float64 = ( # urgency of delivery to customer j
      customers[cust].time_window[2]
      - (b_i + customers[current_id].service_time
         + distances[current_id, cust])
    )
    c_ij::Float64 = (
        δ1 * distances[current_id, cust]
      + δ2 * T_ij
      + δ3 * v_ij
    )

    if c_ij < c_min
      c_min = c_ij
      best_customer = cust
      best_time = b_j
    end
  end

  return (customers[best_customer], best_time)
end

function service_begin_time(
  customers::Vector{Customer},
  distances::Array{Float64, 2},
)::Function
  @inline function service_start(
    i_id::Int, j_id::Int, bi::Float64
  )::Float64
    return max(
      customers[j_id].time_window[1],
      bi + customers[i_id].service_time + distances[i_id, j_id]
    )
  end

  return service_start 
end


function nearest_neighbour(
  instance::Instance,
  args...;
  δ1::Float64 = 0.2,
  δ2::Float64 = 0.5,
  δ3::Float64 = 0.3,
)::Tuple{Float64, Vector{Vector{Int}}}
  result::Vector{Vector{Int}} = []
  cost::Float64 = 0.0

  # unpack instance for faster code, especially in loops
  capacity::Int = instance.q
  customers::Vector{Customer} = instance.customers
  distances::Array{Float64, 2} = instance.distances
  available_customers::Vector{Int} = collect(2:length(customers))

  service_start::Function = service_begin_time(customers, distances)

  println("Running nearest neighbour algorithm...")
  for _ in 1:instance.m # O(m)
    # new vehicle's statistics
    vehicle_route::Vector{Int} = [0]
    b_i::Float64 = 0.0 # begin time of service
    vehicle_capacity::Int = capacity
    current_customer::Customer = customers[1]

    for _ in 1:length(available_customers) + 1 # O(n)
      begin
        # searching for the customers who can feasibly be
        # added (with respect to current vehicle's capacity,
        # its arrival time at depot and time windows) to
        # the end of the currently constucted route
        possible_customers::Vector{Int} = []
        begin_times::Vector{Float64} = [] # begin times of possible customers

        current_id::Int = current_customer.id + 1

        for customer_id::Int in available_customers # O(n)
          customer::Customer = customers[customer_id]
          b_j::Float64 = service_start(current_id, customer_id, b_i)
          return_time::Float64 = service_start(customer_id, 1, b_j)

          # checks:
          # - the vehicle is able to carry customer's package
          # - service start at j is before customers latest time
          # - the vehicle is able to return to depot before
          #   depot's latest time
          if customer.demand <= vehicle_capacity &&
             b_j <= customer.time_window[2] &&
             return_time <= customers[1].time_window[2]
            push!(possible_customers, customer_id)
            push!(begin_times, b_j)
          end
        end
      end # begin

      if isempty(possible_customers)
        cost += distances[current_id, 1]
        push!(vehicle_route, 0)
        push!(result, vehicle_route)
        break
      end

      # changing current customer and its time
      (current_customer, b_i) = find_closest_customer( # O(n)
        possible_customers, begin_times, # possible customers 
        b_i, current_id,                 # current customer
        customers, distances,            # data
        δ1, δ2, δ3                       # weights
      )

      cost += distances[current_id, current_customer.id + 1]
      vehicle_capacity -= current_customer.demand
      
      push!(vehicle_route, current_customer.id)
      filter!(x -> x != current_customer.id + 1, available_customers)
    end # for

    if available_customers == []
      break
    end
  end # for

  return (cost, result)
end
