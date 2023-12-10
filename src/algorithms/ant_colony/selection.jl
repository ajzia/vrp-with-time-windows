function roulette_wheel(
  probabilities::Vector{Float64}
)::Int
  r::Float64 = rand()
  prob::Float64 = 0.0
  for (idx, p) in enumerate(probabilities)
    prob += p
    if r <= prob
      return idx
    end
  end
end


# roulette wheel selection with stochastic acceptance
# http://www.sciencedirect.com/science/article/pii/S0378437111009010
function stochastic_acceptance(
  probabilities::Vector{Float64}
)::Int
  max::Float64 = maximum(probabilities)
  while true
    idx::Int = rand(1:length(probabilities))
    if rand() < probabilities[idx] / max
      return idx
    end
  end
end


function tournament(
  probabilities::Vector{Float64}
)::Int
  n::Int = rand(1:length(probabilities))
  solutions::Vector{Float64} = rand(probabilities, n)

  return argmin(solutions)
end
