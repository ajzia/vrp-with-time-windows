include("./instances/file_parser.jl")
using .FileParser
using ArgParse

const nearest_neighbour_labels::Vector{String} = [
  "\$\\delta1\$",
  "\$\\delta2\$",
  "\$\\delta3\$",
]

instance_data::Dict = Dict(
  "Solomon" => Dict(
    "customers" => [25, 50, 100,],
    "instance_types" => ["C1", "C2", "R1", "R2", "RC1", "RC2",],
  ),
  "Homberger" => Dict(
    "customers" => [200, 400, 600, 800, 1000,],
    "instance_types" => ["C1", "C2", "R1", "R2", "RC1", "RC2",],
  )
)

const algorithms::Vector{String} = [
  "nearest_neighbour",
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

function parse_arguments()::ArgParseSettings
  parse_settings::ArgParseSettings = ArgParseSettings()
  @add_arg_table! parse_settings begin
    "--instance_type", "-i"
      help = "Instance type to use, available: \
              $(collect(keys(instance_data)))"
      arg_type = String
      required = true
    "--instance_family", "-f"
      help = "Instance family, available: \
              $(instance_data["Solomon"]["instance_types"])"
      arg_type = String
      required = true
    "nearest_neighbour", "n"
      help = "Choosing nearest neighbour algorithm to run"
      action = :command
    "populational", "p"
      help = "Choosing populational algorithm to run"
      action = :command
  end

  @add_arg_table! parse_settings["nearest_neighbour"] begin
    "--delta1", "-d"
      help = "Constant for geographical distance being \
              taken into consideration in the process of \
              choosing next customer to visit"
      arg_type = Float64
      required = true
    "--delta2", "-T"
      help = "Constant for temporal closeness being \
              taken into consideration in the process of \
              choosing next customer to visit"
      arg_type = Float64
      required = true
    "--delta3", "-u"
      help = "Constant for urgency of delivery being \
              taken into consideration in the process of \
              choosing next customer to visit"
      arg_type = Float64
      required = true
  end

  return parse_settings
end


function main(args::Dict)::Nothing

end


if abspath(PROGRAM_FILE) == @__FILE__
  parse_settings = parse_arguments()
  args::Dict = parse_args(ARGS, parse_settings)

  if args["%COMMAND%"] == "nearest_neighbour"
    params::Dict = args["nearest_neighbour"]
    if params["delta1"] < 0. || params["delta2"] < 0. || params["delta3"] < 0. ||
       params["delta1"] > 1. || params["delta2"] > 1. || params["delta3"] > 1.
      error("All delta values must be in range (0, 1]")
    end
  end

  main(args)
end
