using JSON
using Dates

file_path(path::String)::String = joinpath(@__DIR__, path)

@inline function read_line_n_times(file::IOStream, n::Int)::Nothing
  for _ in 1:n
    readline(file)
  end
end

@inline split_line(file::IOStream)::Vector{String} =
  split(
    readline(file), r"\s+", keepempty=false
  )


"""
    read_instance(path, no_customers)

  Reads the file `path` and returns it as an
  `Instance` object. `no_customers` is the
  number of customers to be read from the file.
"""
function read_instance(path::String, no_customers::Int=-1)::Instance
  if !isfile(file_path(path))
    throw(ArgumentError("File $path does not exist")) 
  end
  
  if no_customers == 0 || no_customers < -1
    throw(ArgumentError("Number of customers must be greater than 0"))
  end
  
  intance_name::String = ""
  vehicle_info::Vector{String} = []
  customers::Vector{Customer} = []

  open(file_path(path), "r") do file
    intance_name = readline(file)
    read_line_n_times(file, 3)
    vehicle_info = split_line(file)
    read_line_n_times(file, 4)
    depot_info::Vector{String} = split_line(file)
    push!(customers, Customer(depot_info))

    while !(eof(file) || (length(customers) == no_customers + 1))
      push!(customers, Customer(split_line(file)))
    end
  end

  if length(customers) == 1
    throw(ArgumentError("File $path does not contain any customers"))
  end

  return Instance(intance_name, vehicle_info, customers)
end

"""
    write_results(
      instance::Instance,
      nearest_neighbour_routes::Tuple{Float64, Vector{Vector{Int}}},
      acs_results::Tuple{Float64, Vector{Vector{Int}}},
      save_coords::Bool=false
    )

  Writes results of a single file for both
  algorithms in a json file. It is also possible
  to save the coordinates of the customers.
"""
function write_results(
  instance::Instance,
  nearest_neighbour_results::Tuple{Float64, Vector{Vector{Int}}},
  acs_results::Tuple{Float64, Vector{Vector{Int}}},
  save_coords::Bool=false
)::Nothing
  println("Saving results... ")
  results::Dict{String, Any} = Dict(
    "nearest_neighbour" => Dict(
      "cost" => nearest_neighbour_results[1],
      "routes" => nearest_neighbour_results[2],
    ),
    "population" => Dict(
      "cost" => acs_results[1],
      "routes" => acs_results[2],
    ),
  )
  dir::String = file_path("../../results/")
  (!isdir(dir)) && mkdir(dir)

  # will change based on program's parameters
  path::String = 
    "$(instance.name)-\
    n$(length(instance.customers)-1)-\
    m$(instance.m)-\
    q$(instance.q)-\
    $(Dates.now()).json"

  if save_coords == true
    results["coordinates"] =
      [customer.coordinates for customer in instance.customers]

    dir = dir * "coords/"
    (!isdir(dir)) && mkdir(dir)
  end

  println("> Results saved in: ", path)

  open(joinpath(dir, path), "w") do file
    JSON.print(file, results)
  end
end


"""
    dict_to_json(name, no_cust, results)

  Saves `results` in a json file.
"""
function dict_to_json(
  name::String,
  no_cust::Int,
  results::Dict,
)::Nothing
  dir::String = file_path("../../results/")
  (!isdir(dir)) && mkdir(dir)
  dir *= "tuning/"
  (!isdir(dir)) && mkdir(dir)

  path::String = 
    "$(name)-\
    n$(no_cust)-\
    sc$(results["parameters"]["stop_condition"])-\
    sm$(results["parameters"]["max_stop"])-\
    pop$(results["parameters"]["population_size"])-\
    q_0$(results["parameters"]["q_0"])-\
    rho$(results["parameters"]["rho"])-\
    sel$(results["parameters"]["selection"]).json"

  println("> Results saved in: ", joinpath(dir, path))

  open(joinpath(dir, path), "w") do file
    JSON.print(file, results)
  end
end


"""
    get_instance_info(path, plot_type, tuning_folder)

  Gets data from the file `path` and returns a tuple
  with the parameters from the file name and its data.
"""
function get_instance_info(
  path::String,
  plot_type::String,
  tuning_folder::String="",
)::Tuple{Dict, Vector}
  dir::String = "../../results/"
  if plot_type == "routes"
    dir = dir * "coords/"
  elseif plot_type == "tuning"
    dir = dir * "tuning/"
  end

  dir = joinpath(@__DIR__, dir * tuning_folder * "/" * path)
  if !isfile(dir)
    println(dir)
    throw("File $path does not exist")
  end

  data::Dict = JSON.parsefile(
    dir,
    dicttype=Dict
  )

  if plot_type == "routes"
    return (data, [])
  end
  
  parameters::Vector{String} = split(path, "-")
  if length(parameters) < 8
    println(parameters)
    throw("File $path does not contain all the parameters")
  end

  instance_info = [
    parse(Int, parameters[2][2:end]), # no_customers
    parameters[3][3:end], # stop cond
    parse(Int, parameters[4][3:end]), # max_stop
    parse(Int, parameters[5][4:end]), # pop_size
    parse(Float64, parameters[6][4:end]), # q_0
    parse(Float64, parameters[7][4:end]), # rho
    string(parameters[8][4]), # selection
  ]

  return (data, instance_info)
end


function write_latex_table(
  path::String,
  table_titles::Vector{String},
  labels::Vector{String},
  instances::Vector{String},
  table::Dict,
)::Nothing
  dir::String = file_path("../../results")
  (!isdir(dir)) && mkdir(dir)

  dir = joinpath(dir, "tables")
  (!isdir(dir)) && mkdir(dir)

  path::String = joinpath(dir, path)

  println("> Results saved in: ", path)
  for (index, instance) in enumerate(instances)
    for key in sort(collect(keys(table[instance])))
      open(path, "a") do file
        write(file, "\\begin{table}[H]\n")
        write(file, "    \\centering\n")
        write(file, "        \\caption{$(table_titles[index]) with $key customers} ")
        write(file, "\\label{tab:$(table_titles[index])_$key}\n")
        write(file, "        \\begin{tabular}{lrrrr}\n")
        write(file, "        \\toprule\n")
        write(file, "        $(join([labels..., "\$K_{$key}\$", "\$Dist_{$key}\$"], " & ")) \\\\\n")
        write(file, "        \\midrule\n")

        for row in table[instance][key]
          write(file, "        $row\n")
        end

        write(file, "        \\bottomrule\n")
        write(file, "        \\end{tabular}\n")
        write(file, "\\end{table}\n")
        write(file, "\n\n")
      end
    end
  end
end
