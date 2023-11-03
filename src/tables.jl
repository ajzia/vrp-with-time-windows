include("./algorithms/nearest_neighbour.jl")
using ArgParse

const nearest_neighbour_labels::Vector{String} = [
  "\$\\delta_1\$",
  "\$\\delta_2\$",
  "\$\\delta_3\$",
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
        table[instance][no_customers][i] *= test_results["d1"] * " & "
        table[instance][no_customers][i] *= test_results["d2"] * " & "
        table[instance][no_customers][i] *= test_results["d3"] * " & "
        table[instance][no_customers][i] *= test_results[no_customers]["routes"] * " & "
        table[instance][no_customers][i] *= test_results[no_customers]["distance"] * " \\\\"
      end
    end
  end

  return (labels, table)
end

function parse_arguments()::Dict
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
    "--output_file", "-o"
      help = "File name for output table ex. test.tex"
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
      nargs = '+'
    "--delta2", "-T"
      help = "Constant for temporal closeness being \
              taken into consideration in the process of \
              choosing next customer to visit"
      arg_type = Float64
      nargs = '+'
    "--delta3", "-u"
      help = "Constant for urgency of delivery being \
              taken into consideration in the process of \
              choosing next customer to visit"
      arg_type = Float64
      nargs = '+'
  end

  args::Dict = parse_args(ARGS, parse_settings)
  if args["%COMMAND%"] == "nearest_neighbour"
    params::Dict = args["nearest_neighbour"]
    if length(params["delta1"]) != length(params["delta2"]) ||
       length(params["delta1"]) != length(params["delta3"])
      error("Length of delta parameters must be the same!")
    end

    for delta in vcat(params["delta1"], params["delta2"], params["delta3"])
      if delta < 0 || delta > 1
        error("All delta values have to be in range [0, 1]!")
      end
    end
  end

  if !endswith(args["output_file"], ".tex")
    error("Output file must be a .tex file!")
  end

  return args
end


function main(args::Dict)::Nothing
  algorithm::String = args["%COMMAND%"]
  instance_type::String = args["instance_type"]
  instance_family::String = args["instance_family"]

  if instance_type == "Solomon"
    path = "../../resources/Solomon/"
  else
    # TODO: support Homberger instances
    #       (number of customers according
    #        to the instance file name)
    # path = "../../resources/Homberger/"
  end

  results::Dict = Dict()
  instances::Vector{String} = []
  table_titles::Vector{String} = []
  customers::Vector{Int} = instance_data[instance_type]["customers"]

  if algorithm == "nearest_neighbour"
    for file::String in readdir(file_path(path)) # for each instance
      if !startswith(file, instance_family)
        continue
      end
      file_name::String = split(file, ".")[1]
      push!(instances, file_name)
      push!(table_titles, "Results for instance $file_name")

      algorithm_args::Dict = args[algorithm]
      results[file_name] = Dict()

      instance::Instance = read_instance(path * file)
      for i::Int in 1:length(args[algorithm]["delta1"]) # for each test
        results[file_name][i] = Dict()
        results[file_name][i]["d1"] = string(algorithm_args["delta1"][i])
        results[file_name][i]["d2"] = string(algorithm_args["delta2"][i])
        results[file_name][i]["d3"] = string(algorithm_args["delta3"][i])

        for c::Int in customers # for each number of customers
          results[file_name][i][c] = Dict()
          (distance, routes) = nearest_neighbour(
            instance,
            algorithm_args["delta1"][i],
            algorithm_args["delta2"][i],
            algorithm_args["delta3"][i],
          )

          results[file_name][i][c]["routes"] = string(length(routes))
          results[file_name][i][c]["distance"] = string(round(distance, digits=2))
        end
      end
    end

    (labels::Vector{String}, table::Dict) = generate_latex_table(
      algorithm,
      instances,
      customers,
      length(args[algorithm]["delta1"]),
      results,
    )

    write_latex_table(
      args["output_file"],
      table_titles,
      labels,
      instances,
      table
    )
  end # if

end # main

if abspath(PROGRAM_FILE) == @__FILE__
  args::Dict = parse_arguments()
  main(args)
end
