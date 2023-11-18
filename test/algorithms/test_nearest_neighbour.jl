include("../../src/algorithms/nearest_neighbour.jl")
using Test

const five_customer_instance::Instance = read_instance(joinpath(@__DIR__, "./instance5.txt"))

@testset "nearest_neighbour.jl" verbose = true begin
  five_customers::Vector{Customer} = five_customer_instance.customers
  five_distances::Array{Float64, 2} = five_customer_instance.distances
  five_service_start::Function = service_begin_time(five_customers, five_distances)

  @testset "Calculating begin times" begin
    @test five_service_start(1, 1, 0.) == 0.
    @test five_service_start(1, 2, 0.) == 52.
    @test five_service_start(2, 3, 112.) == 206.1
  end
end
