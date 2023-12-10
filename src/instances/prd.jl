using StatsPlots
ENV["GKSwstype"] = "100"

const optimal_solutions::Dict = Dict(
  "C102" => Dict("no_vehicles" => 10, "cost" => 827.3),
  "C104" => Dict("no_vehicles" => 10, "cost" => 827.3),
  "C108" => Dict("no_vehicles" => 10, "cost" => 827.3),
  "R102" => Dict("no_vehicles" => 17, "cost" => 1486.12),    # best known !
  "R104" => Dict("no_vehicles" => 9, "cost" => 1007.31),     # best known !
  "R108" => Dict("no_vehicles" => 9, "cost" => 960.88),      # best known !
  "RC102" => Dict("no_vehicles" => 12, "cost" => 1554.75	), # best known !
  "RC104" => Dict("no_vehicles" => 10, "cost" => 1135.48),   # best known !
  "RC108" => Dict("no_vehicles" => 10, "cost" => 1139.82),   # best known !
  "C202" => Dict("no_vehicles" => 3, "cost" => 589.1),
  "C204" => Dict("no_vehicles" => 3, "cost" => 588.1),
  "C208" => Dict("no_vehicles" => 3, "cost" => 585.8),
  "R202" => Dict("no_vehicles" => 3, "cost" => 1191.7),   # best known !
  "R204" => Dict("no_vehicles" => 2, "cost" => 825.52),   # best known !
  "R208" => Dict("no_vehicles" => 2, "cost" => 726.82),   # best known !
  "RC202" => Dict("no_vehicles" => 3, "cost" => 1365.65), # best known !
  "RC204" => Dict("no_vehicles" => 3, "cost" => 798.46),  # best known !
  "RC208" => Dict("no_vehicles" => 3, "cost" => 828.14),  # best known !
)

const main_solomon_types::Vector{String} = [
  "C", "R", "RC"
]

@inline prd(gen::Float64, opt::Float64)::Float64 = 
  round((gen - opt) / opt * 100, digits=2)

function plot_prd(
  folder::String,
  file::String,
)
  dir::String = joinpath(@__DIR__, "../../results/plots/")
  (data, _) = get_instance_info(file, "tuning", folder)

  instances::Vector{String} = data |> keys |> collect |> sort

  for type in main_solomon_types
    type_instances = filter(x -> startswith(x, type*"1") || startswith(x, type*"2"), instances)

    acs_values::Vector{Float64} = []
    nn_values::Vector{Float64} = []
    for instance in type_instances
      push!(acs_values, prd(data[instance]["acs_cost"], optimal_solutions[instance]["cost"]))
      push!(nn_values, prd(data[instance]["nn_cost"], optimal_solutions[instance]["cost"]))
    end

    if type == "C"
      ylabel ="% od rozwiązania optymalnego"
    else
      ylabel = "% od najlepszego znanego rozwiązania"
    end

    p = groupedbar(
      repeat(type_instances, outer=2),
      reshape([acs_values..., nn_values...], length(type_instances), 2),
      group = repeat(["algorytm mrówkowy", "algorytm najbliższego sąsiada"], inner = length(type_instances)),
      title="Względna różnica dla instancji typu $(type)",
      xlabel="nazwa instancji",
      ylabel=ylabel,
      size=(800, 400),
      lw=0,
      bar_width = 0.5,
      legend=:best, legendcolumns=1,
      color = [:plum2 :cornflowerblue],
      framestyle = :box,
      left_margin=2Plots.mm,
      right_margin=2Plots.mm,
      bottom_margin=4Plots.mm,
      top_margin=4Plots.mm,
    )

    savefig(
      p,
      joinpath(dir, "prd_for_$(type)_$file.svg"),
    )

    for (i, ins) in enumerate(type_instances)
      print(rpad(ins, 6))
      print(rpad("& $(acs_values[i])", 10))
      print(rpad("& $(nn_values[i])", 10))
      println("\\\\")
    end
    
    println("Results saved in: ", joinpath(dir, "prd_for_$(type)_$file.svg"))
  end
end
