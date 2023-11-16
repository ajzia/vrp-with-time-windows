# Solomon's Sequential Insertion I1 Algorithm
#
# Source:
# Marius M. Solomon, (1987)
# Algorithms for the Vehicle Routing and Scheduling Problems with Time Window Constraints.
# Operations Research 35(2):254-265

include("../instances/file_parser.jl")
using Reexport
@reexport using .FileParser

# ********************* COST FUNCTIONS ********************* #

@inline function c_11(
  i_index::Int, u_index::Int, j_index::Int,
  distances::Array{Float64, 2},
  μ::Float64 = 1.
)::Float64
  if μ < 0.
    throw("μ must be greater than or equal to 0.")
  end

  return (distances[i_index, u_index]
          + distances[u_index, j_index]
          - μ * distances[i_index, j_index])
end

@inline function c_12(
  i_index::Int, u_index::Int, j_index::Int,
  service_start::Function,
  b_i::Float64, b_j::Float64
)::Float64
  b_u::Float64 = service_start(i_index, u_index, b_i)
  b_ju::Float64 = service_start(u_index, j_index, b_u)

  return b_ju - b_j
end

@inline function c1(
  i_index::Int, u_index::Int, j_index::Int,
  service_start::Function,
  distances::Array{Float64, 2},
  b_i::Float64, b_j::Float64;
  a1::Float64 = 0.5, a2::Float64 = 0.5,
  μ::Float64 = 1.,
)::Float64
  if (a1 + a2) != 1.0 || (a1 < 0. || a2 < 0.)
    throw("a1 and a2 must be greater than or equal to 0 \
           and their sum must be equal to 1.")
  end

  return (
      a1 * c_11(i_index, u_index, j_index, distances, μ)
      + a2 * c_12(i_index, u_index, j_index, service_start, b_i, b_j)
    )
end

@inline function c2(
  i_index::Int, u_index::Int, j_index::Int,
  service_start::Function,
  distances::Array{Float64, 2},
  b_i::Float64, b_j::Float64;
  a1::Float64 = 0.5, a2::Float64 = 0.5,
  λ::Float64 = 1.,
  μ::Float64 = 1.,
)::Float64
  if λ < 0.
    throw("lambda must be greater than or equal to 0.")
  end

  return (
      λ * distances[1, u_index]
      - c1(i_index, u_index, j_index,
           service_start, distances, b_i, b_j,
           a1=a1, a2=a2, μ=μ
          )
    )
end

# ********************* COST FUNCTIONS ********************* #


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


function find_best_insertion_places(
  customers::Vector{Customer},
  possible_customers::Vector{Int},
  vehicle_route::Vector{Int},
  begin_times::Vector{Float64},
  distances::Array{Float64, 2},
  service_start::Function;
  a1::Float64 = 0.5, a2::Float64 = 0.5,
  μ::Float64 = 1.,
)::Vector{Int}
  # searching for the best place to insert the customers
  best_insertion_places::Vector{Int} = []
  for u_index in possible_customers # O(n)
    best_place::Int = -1
    best_cost::Float64 = Inf

    for (i_route_index, i_id) in enumerate(vehicle_route[1:end-1]) # O(n)
      b_u::Float64 = service_start(i_id + 1, u_index, begin_times[i_route_index])
      # check if customer's begin time is within his time window
      if (b_u > customers[u_index].time_window[2])
        continue
      end

      b_i::Float64 = begin_times[i_route_index]
      prev_route_index::Int = i_route_index
      push_forward::Float64 = -1

      for (j_route_index, j_id) in enumerate(vehicle_route[i_route_index+1:end]) # O(n)
        b_j::Float64 = begin_times[i_route_index + j_route_index]
        if j_route_index == 1
          push_forward = service_start(u_index, j_id + 1, b_u) - b_j
        else
          push_forward = max(0., push_forward - waiting_time(
            prev_route_index, j_route_index,
            vehicle_route, begin_times,
            customers, distances
          ))
        end

        if (b_j + push_forward) > Float64(customers[j_id+1].time_window[2])
          break
        end

        if push_forward == 0 ||
           (i_route_index + j_route_index == length(vehicle_route))

          insertion_cost::Float64 = c1(
            i_id + 1, u_index, vehicle_route[i_route_index + 1] + 1,
            service_start, distances,
            b_i, b_j,
            a1=a1, a2=a2, μ=μ
          )

          if insertion_cost < best_cost
            best_cost = insertion_cost
            best_place = i_route_index # insert after i
          end
        end

        b_i = b_j
        prev_route_index = i_route_index + j_route_index
      end
    end # for
    
    push!(best_insertion_places, best_place)
  end # for

  return best_insertion_places
end


function sequential_insertion(
  instance::Instance,
  args...;
  a1::Float64 = 0.5, a2::Float64 = 0.5,
  λ::Float64 = 1.,
  μ::Float64 = 1.,
)::Tuple{Float64, Vector{Vector{Int}}}
  result::Vector{Vector{Int}} = []
  cost::Float64 = 0.0

  # unpack instance for faster code, especially in loops
  capacity::Int = instance.q
  customers::Vector{Customer} = instance.customers
  distances::Array{Float64, 2} = instance.distances
  available_customers::Vector{Int} = collect(2:length(customers))

  service_start::Function = service_begin_time(customers, distances)

  println("Running sequential insertion algorithm...")
  for _ in 1:instance.m # O(m)
    # new vehicle's statistics
    vehicle_route::Vector{Int} = [0, 0]
    vehicle_capacity::Int = capacity
    begin_times::Vector{Float64} = [
      customers[1].time_window[1],
      customers[1].time_window[2]
    ]

    for _ in 1:length(available_customers) + 1 # O(n)
      # searching for the customers who can feasibly be
      # added (with respect to current vehicle's capacity,
      possible_customers::Vector{Int} = []

      for customer_id::Int in available_customers # O(n)
        customer::Customer = customers[customer_id]

        # checks if the vehicle is able to carry customer's package
        if customer.demand <= vehicle_capacity
          push!(possible_customers, customer_id)
        end
      end

      if isempty(possible_customers)
        push!(result, vehicle_route)
        break
      end

      insertion_places::Vector{Int} = find_best_insertion_places( # O(n^3)
        customers,
        possible_customers, vehicle_route,
        begin_times,
        distances,
        service_start,
        a1=a1, a2=a2, μ=μ
      )

      # find the customer with the best insertion cost
      best_cost::Float64 = Inf
      best_customer::Int = -1
      for (index, customer_idx) in enumerate(possible_customers) # O(n)
        ins_place_index::Int = insertion_places[index]
        if ins_place_index == -1
          continue
        end

        # calculate c2 for inserting customer_id between
        # ins_place_index and ins_place_index + 1
        insertion_cost = c2(
          vehicle_route[ins_place_index] + 1,
          customer_idx,
          vehicle_route[ins_place_index + 1] + 1,
          service_start,
          distances,
          begin_times[ins_place_index],
          begin_times[ins_place_index + 1],
          a1=a1, a2=a2, λ=λ, μ=μ
        )

        if insertion_cost < best_cost
          best_cost = insertion_cost
          best_customer = index
        end
      end

      if best_customer == -1
        push!(result, vehicle_route)
        break
      end

      customer_index::Int = possible_customers[best_customer]
      i_index::Int = insertion_places[best_customer]

      # update vehicle's capacity and cost of the route
      vehicle_capacity -= customers[customer_index].demand

      cost = (cost
              - distances[vehicle_route[i_index] + 1, vehicle_route[i_index + 1] + 1]
              + distances[vehicle_route[i_index] + 1, customer_index]
              + distances[customer_index, vehicle_route[i_index + 1] + 1]
      )

      # remove customer from available customers
      filter!(x -> x != customer_index, available_customers)

      # update begin times
      b_u::Float64 = service_start(
        vehicle_route[i_index] + 1,
        customer_index,
        begin_times[i_index]
      )

      begin_times = vcat(begin_times[1:i_index], b_u)
      for (j_index, j_id) in enumerate(vehicle_route[i_index+1:end])
        b_i::Float64 = begin_times[end]
        b_j::Float64 = service_start(vehicle_route[j_index + i_index] + 1, j_id + 1, b_i)

        push!(begin_times, b_j)
      end

      # insert new customer
      insert!(vehicle_route, i_index + 1, customer_index - 1)
    end # for

    if available_customers == []
      break
    end
  end # for

  return (cost, result)
end
