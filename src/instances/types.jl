mutable struct Customer
  id::Int
  coordinates::Tuple{Int, Int}
  demand::Int
  time_windows::Tuple{Float64, Float64}
  service_time::Int

  function Customer(
    customer_info::Vector{String}
  )::Customer
    id::Int = parse(Int, customer_info[1])
    coordinates::Tuple{Int, Int} = (
      parse(Int, customer_info[2]),
      parse(Int, customer_info[3])
    )
    demand::Int = parse(Int, customer_info[4])
    time_windows::Tuple{Float64, Float64} = (
      parse(Int, customer_info[5]),
      parse(Int, customer_info[6])
    )
    @assert time_windows[1] <= time_windows[2]
    service_time::Int = parse(Int, customer_info[7])
    new(id, coordinates, demand, time_windows, service_time)
  end
end


struct Instance
  name::String
  m::Int
  q::Int
  depot::Customer
  customers::Vector{Customer}
  distances::Array{Float64, 2}

  function Instance(
    name::String,
    vehicle_info::Vector{String},
    customers::Vector{Customer}
  )::Instance
    m::Int = parse(Int, vehicle_info[1])
    q::Int = parse(Int, vehicle_info[2])

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

    new(name, m, q, customers[1], customers[2:end], distances)
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
