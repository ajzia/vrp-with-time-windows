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
  i_id::Int, u_id::Int, j_id::Int,
  distances::Array{Float64, 2},
  μ::Float64 = 1.
)::Float64
  if (μ < 0.)
    throw("μ must be greater than or equal to 0.")
  end

  return distances[i_id, u_id] + distances[u_id, j_id] - μ * distances[i_id, j_id]
end

@inline function c_12(
  i_id::Int, u_id::Int, j_id::Int,
  service_start::Function,
)
  b_j::Float64 = service_start(i_id, j_id, b_i)
  b_ju::Float64 = service_start(u_id, j_id, b_ju)

  return b_ju - b_j
end

@inline function c1(
  i_id::Int, u_id::Int, j_id::Int,
  distances::Array{Float64, 2},
  service_start::Function;
  a1::Float64 = 0.5, a2::Float64 = 0.5,
  μ::Float64 = 1.,
)::Float64
  if (a1 + a2) != 1.0 || (a1 < 0. || a2 < 0.)
    throw("a1 and a2 must be greater than or equal to 0 \
           and their sum must be equal to 1.")
  end

  return (
      a1 * c_11(i_id, u_id, j_id, distances, μ)
      + a2 * c_12(i_id, u_id, j_id, service_start)
    )
end

@inline function c2(
  i_id::Int, u_id::Int, j_id::Int,
  service_start::Function,
  distances::Array{Float64, 2};
  a1::Float64 = 0.5, a2::Float64 = 0.5,
  λ::Float64 = 1.,
  μ::Float64 = 1.,
)
  if (λ < 0.)
    throw("lambda must be greater than or equal to 0.")
  end

  return (
      λ * distances[1, u_id]
      - c1(i_id, u_id, j_id, distances, service_start, a1=a1, a2=a2, μ=μ)
    )
end

# ********************* COST FUNCTIONS ********************* #


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
