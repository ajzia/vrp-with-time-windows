module IO
  include("types.jl")
  export file_path, read_instance

  # saving results to .json file
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

  # tests: correct number of customers when chosen
  # error tests: no_customers < -1, no_customers == 0, file does not exist
  # read file with no customers ?
  function read_instance(path::String, no_customers::Int=-1)::Instance
    if (!isfile(file_path(path)))
      println("File $path does not exist")
      return
    end

    if (no_customers == 0 || no_customers < -1)
      println("Number of customers must be greater than 0")
      return
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

    if (length(customers) == 1)
      println("File $path does not contain any customers")
      return
    end

    return Instance(intance_name, vehicle_info, customers)
  end


  function write_results(
    instance::Instance,
    routes::Vector{Vector{Int}},
    cost::Float64,
    save_coords::Bool=false
  )::Nothing
    results::Dict = Dict(
      "cost" => cost,
      "routes" => routes,
    )
  
    dir::String = joinpath(
      @__DIR__,
      "../../results/data/"
    )

    # will change based on program's parameters
    path::String = "$(instance.name)_n$(length(instance.customers))_m$(instance.m)_q$(instance.q)_$(Dates.now()).json"
  
    if (save_coords == true)
      results["coordinates"] = [
        instance.depot.coordinates;
        [customer.coordinates for customer in instance.customers]
      ]
  
      dir = dir * "coords/"
    end
  
    (!isdir(dir)) || mkdir(dir)
  
    open(joinpath(dir, path), "w") do file
      JSON.print(file, results)
    end
  end


end # module IO
