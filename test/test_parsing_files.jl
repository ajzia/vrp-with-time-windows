using Test

@testset "Parsing files" verbose = true begin
  @testset "types.jl" begin
    @testset "Creating Customer" begin
      # no info about customer
      customer_info::Vector{String} = []
      @test_throws "Not enough / too much information about customer. \
        Required: 7, Got: 0" Customer(customer_info)
      
      # too little info about customer
      customer_info = ["1111", "4444", "2322", "111"]
      @test_throws "Not enough / too much information about customer. \
        Required: 7, Got: 4" Customer(customer_info)

      # too much info about customer
      customer_info = ["1", "2", "3", "4", "5", "6", "7", "8"]
      @test_throws "Not enough / too much information about customer. \
        Required: 7, Got: 8" Customer(customer_info)

      # customer id < 0
      customer_info = ["-1", "2", "3", "4", "5", "6", "7"]
      @test_throws "Id cannot be a negative number" Customer(customer_info)

      # time window starts before universal start time = 0
      customer_info = ["1", "2", "3", "4", "-1", "6", "7"]
      @test_throws "Time window should start at least at 0 and\
      at most be equal to the end time" Customer(customer_info)

      # time window ends before its start time
      customer_info = ["1", "2", "3", "4", "10", "6", "7"]
      @test_throws "Time window should start at least at 0 and\
      at most be equal to the end time" Customer(customer_info)

      # correct customer creation
      customer_info = ["1", "2", "3", "4", "5", "6", "7"]
      @test Customer(customer_info) isa Customer
    end

    @testset "Creating Instance" begin
      customers::Vector{Customer} = [
        Customer(["0", "2", "3", "0", "5", "6", "7"])
        Customer(["0", "2", "3", "5", "5", "6", "7"])
        Customer(["2", "2", "4", "4", "7", "8", "7"])
        Customer(["3", "2", "5", "4", "5", "6", "7"])
      ]
      instance_name::String = ""
      vehicle_info::Vector{String} = []

      # empty instance name
      @test_throws "Instance name cannot be \
        empty" Instance(instance_name, vehicle_info, customers)

      # no vehicle info
      instance_name = "name"
      @test_throws "Not enough information about instance's vehicles.\
        Required: 2, Got: 0" Instance(instance_name, vehicle_info, customers)

      # number of vehicles negative or equal to 0
      vehicle_info = ["0", "4"]
      @test_throws "Number of vehicles has to be positive. \
        Got: 0"  Instance(instance_name, vehicle_info, customers)

      # vehicle capacity lower than customer demand
      vehicle_info[1] = "2"
      @test_throws "Vehicle capacity has to be positive and \
        higher than any customer demand. Required: 5, \
        Got: 4"  Instance(instance_name, vehicle_info, customers)

      # customers don't have uniqe id
      vehicle_info[2] = "5"
      @test_throws "All customers have to have their own uniqe \
        id" Instance(instance_name, vehicle_info, customers)

      # customers don't have unique coordinates
      customers[2].id = 1
      @test_throws "All customers have to have their own uniqe \
        coordinates" Instance(instance_name, vehicle_info, customers)

      # customers time window starts after depot's closing time
      customers[1].coordinates = (1, 2)
      @test_throws "Customers time window must start before depot's \
        closing time." Instance(instance_name, vehicle_info, customers)

      # correct instance creation
      customers[3].time_window = (1, 5)
      @test Instance(instance_name, vehicle_info, customers) isa Instance
    end
  end

  @testset "file_parser.jl" begin
    @testset "Reading instance" begin
      test_file::String = joinpath(@__DIR__, "empty_file.txt")
      open(test_file, "w") do file write(file, "") end

      @test_throws ArgumentError read_instance("nonexistent_file.txt")

      # wrong numer of customers
      @test_throws ArgumentError read_instance(test_file, 0)
      @test_throws ArgumentError read_instance(test_file, -2)

      # wrong types of arguments
      open(test_file, "w") do file
        write(file, "name\n\n\n\n3 10\n\n\n\n\n")
        write(file, "0 40 50 0 0 1236 a")
      end
      @test_throws ArgumentError read_instance(test_file)

      # no customers in file
      open(test_file, "w") do file
        write(file, "name\n\n\n\n3 10\n\n\n\n\n")
        write(file, "0 40 50 0 0 1236 0\n")
      end
      @test_throws ArgumentError read_instance(test_file)

      # good parsing
      open(test_file, "w") do file
        write(file, "name\n\n\n\n3 10\n\n\n\n\n")
        write(file, "0 40 50 0 0 1236 0\n")
        write(file, "1 55 87 10 76 1050 60\n")
        write(file, "2 11 11 10 11 1111 10\n")
      end
      @test read_instance(test_file) isa Instance

      # good parsing with specified number of customers
      @test length(read_instance(test_file, 1).customers) == 2

      rm(test_file)
    end
  end
end
