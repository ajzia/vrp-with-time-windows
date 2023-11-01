include("./instances/file_parser.jl")
using .FileParser

const nearest_neighbour_labels::Vector{String} = [
  "\$\\delta1\$",
  "\$\\delta2\$",
  "\$\\delta3\$",
]

const solomon_customers::Vector{Int} = [
  25, 50, 100,
]

const homberger_customers::Vector{Int} = [
  # in homberger, we take into consideration
  # all of the instance's customers,
  # its varying from 200 to 1000 
]

function Base.zeros(::Type{String}, n::Int)::Vector{String}
  return ["" for _ in 1:n]
end

function generate_latex_table(
  algorithm::String,
  instances::Vector{String},
  customers::Vector{Int},    # Customer numbers
  no_tests::Int,
  results::Dict,
)::Tuple{Vector{String}, Dict{String, Dict}}
  labels::Vector{String} = []
  if algorithm == "nearest_neighbour"
    push!(labels, nearest_neighbour_labels...)
  end

  table::Dict{String, Dict} = Dict()
  for instance in instances
    table[instance] = Dict()
    for no_customers in customers
      table[instance][no_customers] = zeros(String, no_tests)
      for i in 1:no_tests
        test_results::Dict = results[instance][i]
        table[instance][no_customers][i] *= test_results["δ1"] * " & "
        table[instance][no_customers][i] *= test_results["δ2"] * " & "
        table[instance][no_customers][i] *= test_results["δ3"] * " & "
        table[instance][no_customers][i] *= test_results[no_customers]["routes"] * " & "
        table[instance][no_customers][i] *= test_results[no_customers]["distance"] * " \\\\"
      end
    end
  end

  return (labels, table)
end
