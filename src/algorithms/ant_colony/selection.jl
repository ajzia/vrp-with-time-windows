function roulette_wheel(
  probabilities::Vector{Float64},
  args...
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
  probabilities::Vector{Float64},
  args...
)::Int
  max::Float64 = maximum(probabilities)
  while true
    idx::Int = rand(1:length(probabilities))
    if rand() < probabilities[idx] / max
      return idx
    end
  end
end


# "Tournament Selection Based Artificial Bee Colony Algorithm with Elitist Strategy"
#     -> Meng-Dan Zhang, Zhi-Hui Zhan, Jing-Jing Li & Jun Zhang 
function tournament(
  probabilities::Vector{Float64},
  lambda::Float64 = 0.5
)::Int
  n::Int = ceil(lambda*length(probabilities))
  solutions::Vector{Float64} = rand(probabilities, n)

  return argmin(solutions)
end
