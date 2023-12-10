mutable struct Customer
  id::Int
  coordinates::Tuple{Int, Int}
  demand::Int
  time_window::Tuple{Float64, Float64}
  service_time::Int

  function Customer(
    customer_info::Vector{String}
  )::Customer
    if length(customer_info) != 7
      throw(
        "Not enough / too much information about customer. \
         Required: 7, Got: $(length(customer_info))"
      )
    end

    id::Int = parse(Int, customer_info[1])
    if id < 0
      throw("Id cannot be a negative number")
    end

    coordinates::Tuple{Int, Int} = (
      parse(Int, customer_info[2]),
      parse(Int, customer_info[3])
    )
    demand::Int = parse(Int, customer_info[4])
    time_window::Tuple{Float64, Float64} = (
      parse(Int, customer_info[5]),
      parse(Int, customer_info[6])
    )
    if !(0 <= time_window[1] <= time_window[2])
      throw(
        "Time window should start at least at 0 and\
         at most be equal to the end time")
    end

    service_time::Int = parse(Int, customer_info[7])
    new(id, coordinates, demand, time_window, service_time)
  end
end


struct Instance
  name::String
  m::Int
  q::Int
  customers::Vector{Customer}
  distances::Array{Float64, 2}

  function Instance(
    name::String,
    vehicle_info::Vector{String},
    customers::Vector{Customer}
  )::Instance
    if isempty(name)
      throw("Instance name cannot be empty")
    end

    if length(vehicle_info) != 2
      throw(
        "Not enough information about instance's vehicles.\
         Required: 2, Got: $(length(vehicle_info))"
      )
    end

    m::Int = parse(Int, vehicle_info[1])
    q::Int = parse(Int, vehicle_info[2])
    if m <= 0
      throw("Number of vehicles has to be positive. Got: $(m)")
    end

    if !(0 < maximum([c.demand for c in customers]) <= q)
      throw(
        "Vehicle capacity has to be positive and higher \
         than any customer demand. Required: \
         $(maximum([c.demand for c in customers])), Got: $(q)"
      )
    end

    # operating based on id is important, hence checking
    # whether each customer has their own unique id
    if length(unique([c.id for c in customers])) != length(customers)
      throw("All customers have to have their own uniqe id")
    end

    if length(unique([c.coordinates for c in customers])) != length(customers)
      throw("All customers have to have their own uniqe coordinates")
    end

    @inline euclidean_distance(coords1, coords2)::Float64 =
      trunc(sqrt(
          (coords1[1] - coords2[1])^2 +
          (coords1[2] - coords2[2])^2
        ), digits=1
      )

    # calculate distances
    no_customers::Int = length(customers)
    distances::Array{Float64, 2} = zeros(no_customers, no_customers)
    for i in 1:no_customers, j in 1:no_customers
      distances[i, j] = euclidean_distance(
        customers[i].coordinates,
        customers[j].coordinates
      )
    end

    # customers cannot have time window starting after depot's
    # closing time (it would make visiting the customer impossible)
    depot::Customer = customers[1]
    depot_closing_time::Int = depot.time_window[2]
    for c in customers[2:end]
      if c.time_window[1] >= depot_closing_time
        throw(
          "Customers time window must start before \
           depot's closing time."
        )
      end
    end

    new(name, m, q, customers, distances)
  end
end


function print_instance(instance::Instance)::Nothing
  println("Instance: ", instance.name)
  println("Number of vehicles: ", instance.m)
  println("Vehicle capacity: ", instance.q)
  println("Depot: ", instance.depot)
  println("Customers: ")

  for customer in instance.customers
    print("   ")
    println(customer)
  end

  println("Distances: ")
  no_vertices::Int = length(instance.distances[:, 1])
  for i in 1:no_vertices
    print("   ")
    println(instance.distances[i, :])
  end
end
