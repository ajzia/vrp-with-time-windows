module FileParser
  include("types.jl")
  export Instance, Customer
  export file_path, read_instance, write_results
  export write_latex_table

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


  function write_results(
    instance::Instance,
    nearest_neighbour_routes::Vector{Vector{Int}},
    nearest_neighbour_cost::Float64,
    routes::Vector{Vector{Int}},
    cost::Float64,
    save_coords::Bool=false
  )::Nothing
    println("Saving results... ")
    results::Dict{String, Any} = Dict(
      "nearest_neighbour" => Dict(
        "cost" => nearest_neighbour_cost,
        "routes" => nearest_neighbour_routes,
      ),
      "population" => Dict(
        "cost" => cost,
        "routes" => routes,
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

end # module FileParser
