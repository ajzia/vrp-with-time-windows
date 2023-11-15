include("../../src/algorithms/sequential_insertion.jl")
using Test

const three_customer_instance::Instance = read_instance(joinpath(@__DIR__, "./instance3.txt"))

@testset "Sequential insertion algorithm" verbose = true begin
  three_customers::Vector{Customer} = three_customer_instance.customers
  three_distances::Array{Float64, 2} = three_customer_instance.distances
  three_service_start::Function = service_begin_time(three_customers, three_distances)

  @testset "service_begin_time" begin
    @test three_service_start(1, 1, 0.) == 0.
    @test three_service_start(1, 2, 0.) == 112.
    @test three_service_start(2, 3, 112.) == 206.1
  end

  @testset "Cost functions" begin
    @testset "c_11" begin
      @test_throws "μ must be greater than or equal to 0." c_11(1, 2, 3, three_distances, -1.)

      @test c_11(1, 2, 3, three_distances) == 7.5
      @test c_11(1, 2, 3, three_distances, 0.) == 20.5
      @test c_11(1, 2, 3, three_distances, 2.5) == -12

      @test c_11(1, 3, 1, three_distances) == 26
      @test c_11(1, 1, 1, three_distances) == 0
    end
    
    @testset "c_12" begin
      @test c_12(1, 2, 3, three_service_start, 0., 22.) ≈ 184.1
      @test c_12(1, 3, 2, three_service_start, 0., 112.) ≈ 4.1
      @test c_12(1, 2, 1, three_service_start, 0., 0.) ≈ 218.4
    end

    @testset "c_1" begin
      @test_throws "a1 and a2 must be greater than or equal to 0 \
      and their sum must be equal to 1." c1(1, 2, 3, three_service_start, three_distances, 1., 1., a1=1., a2=1.)

      @test_throws "a1 and a2 must be greater than or equal to 0 \
      and their sum must be equal to 1." c1(1, 2, 3, three_service_start, three_distances, 1., 1., a1=2., a2=-1.)

      @test_throws "a1 and a2 must be greater than or equal to 0 \
      and their sum must be equal to 1." c1(1, 2, 3, three_service_start, three_distances,  1., 1., μ=-1.)

      @test c1(1, 2, 3, three_service_start, three_distances, 0., 22., a1=1., a2=0.) ≈ 7.5
      @test c1(1, 2, 3, three_service_start, three_distances, 0., 22., a1=0., a2=1.) ≈ 184.1

      @test c1(1, 2, 3, three_service_start, three_distances, 0., 22., μ=2.5) ≈ 86.05
    end

    @testset "c_2" begin
      @test_throws "lambda must be greater than or equal to 0." c2(1, 2, 3, three_service_start, three_distances, 1., 1., λ=-1.)

      @test c2(1, 2, 3, three_service_start, three_distances, 0., 22., λ=0.) ≈ -95.8
      @test c2(1, 2, 3, three_service_start, three_distances, 0., 22., λ=1.) ≈ -79.4
    end
  end
end
