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

  @testset "Finding closest customer" begin
    @test_throws "δ1, δ2 and δ3 must be greater than or equal to 0" find_closest_customer(
      [2, 3, 4, 5], [52., 22., 200., 6.7], 0., 1, five_customers, five_distances, -1., 0., 0.
    )

    @test_throws "δ1, δ2 and δ3 must sum to 1" find_closest_customer(
      [2, 3, 4, 5], [52., 22., 200., 6.7], 0., 1, five_customers, five_distances, 0., 0., 0.
    )

    @test_nowarn find_closest_customer(
      [2, 3, 4, 5], [52., 22., 200., 6.7], 0., 1, five_customers, five_distances, 0.3, 0.5, 0.2
    )

    @test find_closest_customer(
      [2, 3, 4, 5], [52., 22., 200., 6.7], 0., 1, five_customers, five_distances, 0.3, 0.5, 0.2
    ) == (five_customers[3], 22.)
  end

  @testset "Nearest neighbour algorithm" begin
    @test_nowarn nearest_neighbour(five_customer_instance)

    (cost, routes) = nearest_neighbour(five_customer_instance)
    @test length(routes) <= five_customer_instance.m
    for route in routes
      @test sum([five_customer_instance.customers[id+1].demand for id in route]) <= five_customer_instance.q
    end
  end
end
