module IO
  include("types.jl")
  export Instance, Customer
  export file_path, read_instance, write_results

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
    greedy_routes::Vector{Vector{Int}},
    greedy_cost::Float64,
    routes::Vector{Vector{Int}},
    cost::Float64,
    save_coords::Bool=false
  )::Nothing
    
    results::Dict{String, Any} = Dict(
      "greedy" => Dict(
        "cost" => greedy_cost,
        "routes" => greedy_routes,
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
      n$(length(instance.customers))-\
      m$(instance.m)-\
      q$(instance.q)-\
      $(Dates.now()).json"
  
    if save_coords == true
      results["coordinates"] = [
        instance.depot.coordinates;
        [customer.coordinates for customer in instance.customers]
      ]
  
      dir = dir * "coords/"
      (!isdir(dir)) && mkdir(dir)
    end
  
    open(joinpath(dir, path), "w") do file
      JSON.print(file, results)
    end
  end

end # module IO
