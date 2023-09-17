@inline function reduce_arrival_time(
  time_window::Tuple{Float64, Float64},
  arrival_times::Vector{Float64}
)
  return max(
    time_window[1], min(
      time_window[2], minimum(
          arrival_times
        )
      )
    )
end


@inline function reduce_departure_time(
  time_window::Tuple{Float64, Float64},
  departure_times::Vector{Float64}
)
  return min(
    time_window[2], max(
      time_window[2], maximum(
        departure_times
      )
    )
  )
end


function reduce_time_windows(
  time_windows::Vector{Tuple{Float64, Float64}},
  distances::Array{Float64, 2}
)::Vector{Tuple{Float64, Float64}}
  no_windows::Int = length(time_windows)
  reduced_windows = Vector{Tuple{Float64, Float64}}(undef, no_windows)
  reduced_windows[1] = time_windows[1]
  
  while true
    for (customer, window) in enumerate(time_windows)
      if (customer == 1) continue end
      # minimal arrival time from predecessors
      reduced_windows[customer] = (
        reduce_arrival_time(
          window, [
            time_windows[i][1] + distances[i, customer]
              for i in 1:no_windows if i != customer
          ]
        ),
        window[2]
      )
      
      # minimal arrival time to successors
      reduced_windows[customer] = (
        reduce_arrival_time(
          window, [
            time_windows[j][1] - distances[customer, j]
              for j in 1:no_windows if j != customer
            ]
          ),
          window[2]
      )

      # maximal departure time from predecessors
      reduced_windows[customer] = (
        window[1],
        reduce_departure_time(
          window, [
            time_windows[i][2] + distances[i, customer]
              for i in 1:no_windows if i != customer
          ]
        )
      )

      # maximal departure time to successors
      reduced_windows[customer] = (
        window[1],
        reduce_departure_time(
          window, [
            time_windows[j][2] - distances[customer, j]
              for j in 1:no_windows if j != customer
          ]
        )
      )
    end

    if (reduced_windows == time_windows)
      break
    end

    time_windows = copy(reduced_windows)
  end

  return reduced_windows
end
