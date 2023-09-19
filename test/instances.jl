include("../src/instances/file_parser.jl")
using .IO
using Test

test_file::String = joinpath(@__DIR__, "empty_file.txt")
open(test_file, "w") do file write(file, "") end

@testset verbose = true "File parsing" begin
  @testset "Reading files" begin
    @test_throws ArgumentError read_instance("nonexistent_file.txt")

    # wrong numer of customers
    @test_throws ArgumentError read_instance(test_file, 0)
    @test_throws ArgumentError read_instance(test_file, -2)
    
    # the file doesn't contain depot info
    @test_throws BoundsError read_instance(test_file)

    # too little info about depot
    open(test_file, "w") do file
      write(file, "name\n\n\n\n3\n\n\n\n\n")
    end
    @test_throws BoundsError read_instance(test_file)

    # wrong types of arguments
    open(test_file, "a") do file
      write(file, "0 40 50 0 0 1236 a")
    end
    @test_throws ArgumentError read_instance(test_file)

    # no customers in file
    open(test_file, "w") do file
      write(file, "name\n\n\n\n3\n\n\n\n\n")
      write(file, "0 40 50 0 0 1236 0\n")
    end
    @test_throws ArgumentError read_instance(test_file)

    # customer's time windows are not correct (a > b)
    open(test_file, "a") do file
      write(file, "1 55 87 10 76 75 60\n")
    end
    @test_throws AssertionError read_instance(test_file)

    # vehicle info does not contain vehicle's capacity
    open(test_file, "w") do file
      write(file, "name\n\n\n\n3\n\n\n\n\n")
      write(file, "0 40 50 0 0 1236 0\n")
      write(file, "1 55 87 10 76 1050 60\n")
    end
    @test_throws BoundsError read_instance(test_file)

    # good parsing
    open(test_file, "w") do file
      write(file, "name\n\n\n\n3 10\n\n\n\n\n")
      write(file, "0 40 50 0 0 1236 0\n")
      write(file, "1 55 87 10 76 1050 60\n")
      write(file, "2 11 11 10 11 1111 10\n")
    end
    @test read_instance(test_file) isa Main.IO.Instance

    # good parsing with specified number of customers
    @test length(read_instance(test_file, 1).customers) == 1

    rm(test_file)
  end
end
