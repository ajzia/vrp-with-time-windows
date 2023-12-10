using Test

five_customer_instance::Instance = read_instance(joinpath(@__DIR__, "./instance5.txt"))

@testset "sequential_insertion.jl" verbose = true begin
  five_customers::Vector{Customer} = five_customer_instance.customers
  five_distances::Array{Float64, 2} = five_customer_instance.distances
  five_service_start::Function = service_begin_time(five_customers, five_distances)

  @testset "Calculating begin times" begin
    @test five_service_start(1, 1, 0.) == 0.
    @test five_service_start(1, 2, 0.) == 52.
    @test five_service_start(2, 3, 112.) == 206.1
  end

  @testset "Calculating waiting time" begin
    @test waiting_time(
      1, 2,
      [0, 0],
      [0., 400.],
      five_customers,
      five_distances,
    ) == 400.

    @test waiting_time(
      1, 2,
      [0, 2, 3, 0],
      [0., 22, 200, 308.7],
      five_customers,
      five_distances,
    ) == 9

    @test waiting_time(
      2, 3,
      [0, 2, 3, 0],
      [0., 22., 200., 308.7],
      five_customers,
      five_distances,
    ) == 82.7

    @test waiting_time(
      3, 4,
      [0, 2, 3, 0],
      [0., 22., 200., 308.3],
      five_customers,
      five_distances,
    ) == 0
  end

  @testset "Cost functions" begin
    @testset "c_11" begin
      @test_throws "μ must be greater than or equal to 0" c_11(1, 2, 3, five_distances, -1.)

      @test c_11(1, 2, 3, five_distances) == 7.5
      @test c_11(1, 2, 3, five_distances, 0.) == 20.5
      @test c_11(1, 2, 3, five_distances, 2.5) == -12

      @test c_11(1, 3, 1, five_distances) == 26
      @test c_11(1, 1, 1, five_distances) == 0
    end
    
    @testset "c_12" begin
      @test c_12(1, 2, 3, five_service_start, 0., 22.) ≈ 124.1
      @test c_12(1, 3, 2, five_service_start, 0., 112.) ≈ 4.1
      @test c_12(1, 2, 1, five_service_start, 0., 0.) ≈ 158.4
    end

    @testset "c_1" begin
      @test_throws "a1 and a2 must be greater than or equal to 0 \
      and their sum must be equal to 1" c1(1, 2, 3, five_service_start, five_distances, 1., 1., a1=1., a2=1.)

      @test_throws "a1 and a2 must be greater than or equal to 0 \
      and their sum must be equal to 1" c1(1, 2, 3, five_service_start, five_distances, 1., 1., a1=2., a2=-1.)

      @test_throws "a1 and a2 must be greater than or equal to 0 \
      and their sum must be equal to 1" c1(1, 2, 3, five_service_start, five_distances,  1., 1., μ=-1.)

      @test c1(1, 2, 3, five_service_start, five_distances, 0., 22., a1=1., a2=0.) ≈ 7.5
      @test c1(1, 2, 3, five_service_start, five_distances, 0., 22., a1=0., a2=1.) ≈ 124.1

      @test c1(1, 2, 3, five_service_start, five_distances, 0., 22., μ=2.5) ≈ 56.05
    end

    @testset "c_2" begin
      @test_throws "lambda must be greater than or equal to 0" c2(1, 2, 3, five_service_start, five_distances, 1., 1., λ=-1.)

      @test c2(1, 2, 3, five_service_start, five_distances, 0., 22., λ=0.) ≈ -65.8
      @test c2(1, 2, 3, five_service_start, five_distances, 0., 22., λ=1.) ≈ -49.4
    end
  end

  @testset "Choosing best insertion place" begin
    @test find_best_insertion_places(
      five_customers,
      Vector{Int}(), # indexes
      [0, 0],        # ids
      [0, five_customers[1].time_window[2]],
      five_distances,
      five_service_start,
    ) == []

    @test find_best_insertion_places(
      five_customers,
      [2],       # ids: [1]
      [0, 2, 0], # ids
      [0, 22, five_customers[1].time_window[2]],
      five_distances,
      five_service_start,
    ) == [-1]

    @test find_best_insertion_places(
      five_customers,
      [2, 4, 5], # idx: [1, 3, 4]
      [0, 2, 0], # ids
      [0, 22, five_customers[1].time_window[2]],
      five_distances,
      five_service_start,
    ) == [-1, 2, 2]


    @test find_best_insertion_places(
      five_customers,
      [3, 4], # id: [2, 3]
      [0, 1, 4, 0], # ids
      [0, 52, 152, five_customers[1].time_window[2]],
      five_distances,
      five_service_start,
    ) == [-1, 3]

    @test find_best_insertion_places(
      five_customers,
      [3],             # ids: [2]
      [0, 1, 4, 3, 0], # ids
      [0, 52, 152, 253.7, five_customers[1].time_window[2]],
      five_distances,
      five_service_start,
    ) == [-1]
  end

  @testset "Sequential insertion algorithm" begin
    @test_nowarn sequential_insertion(five_customer_instance)

    (cost, routes) = sequential_insertion(five_customer_instance, 1)
    @test length(routes) <= five_customer_instance.m
    for route in routes
      @test sum([five_customer_instance.customers[id+1].demand for id in route]) <= five_customer_instance.q
    end

  end
end
