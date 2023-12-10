using JSON
using Plots
ENV["GKSwstype"] = "100"

export plot_routes

# Due to the fact that many instances have big
# number of available vehicles and that every
# route has to have a different color, I created
# my own palette consisting of 44 colors, while
# the basic color palette only has 16 colors.
color_palette = [
  :cornflowerblue, :maroon1, :orange, :lawngreen,
  :magenta4, :gold, :orchid1, :cyan,
  :lightsalmon1, :purple1, :dodgerblue, :fuchsia,
  :navajowhite4, :indianred1, :aquamarine, :darkgoldenrod2,
  :indigo, :lightseagreen, :rosybrown2, :darkslategray1,
  :tomato2, :mediumvioletred, :midnightblue, :olivedrab3,
  :mediumpurple1, :salmon4, :yellow, :hotpink1,
  :slateblue2, :brown2, :red4, :purple4,
  :darkgreen, :aquamarine4, :maroon3, :seagreen1,
  :brown1, :olive, :blue, :violetred2,
  :brown, :darkturquoise, :slategray, :skyblue2
]

const polish_algorithm_names::Dict = Dict(
  "nearest_neighbour" => "najbliższego sąsiada",
  "population" => "mrówkowego",
)


function plot_routes(
  path::String,
)::Nothing
  println("Generating plots...")
  (data::Dict, instance_info::Vector) = get_instance_info(path, "routes")
  instance_name::String = split(path, "-")[1]

  coords::Vector{Tuple{Int, Int}} =
    [(x,y) for (x, y) in data["coordinates"]]

  max_x::Int = maximum([x for (x, y) in coords]) + 1
  max_x = max_x + (10 - max_x % 10)
  max_y::Int = maximum([y for (x, y) in coords]) + 1
  max_y = max_y + (10 - max_y % 10)

  for algorithm in ["nearest_neighbour", "population"]
    if isempty(data[algorithm]["routes"])
      continue
    end

    # Customers' coordinates
    p = plot(
      coords[2:end],
      seriestype=:scatter,
      markersize=4,
      markershape=:hexagon,
      label="Klienci",
      color=:grey33,
      markerstrokecolor=:grey33
    )
    
    for (i, route) in enumerate(data[algorithm]["routes"])
      x_coords = [
        [coords[j+1][1], coords[k+1][1]] for (j, k) in zip(route, route[2:end])]
      y_coords = [
        [coords[j+1][2], coords[k+1][2]] for (j, k) in zip(route, route[2:end])]

      # Routes
      plot!(x_coords, y_coords,
        GR.setarrowsize(0.85),
        arrow=Plots.Arrow(:closed, :head, 0.1, 0.1),
        linewidth=1,
        title="Rozwiązanie $instance_name za pomocą algorytmu \
        $(polish_algorithm_names[algorithm])",
        label="",
        color=color_palette[i],
      )
      plot!([], [], label="Trasa $i", color=color_palette[i])
    end

    # Depot's coordinates
    plot!(
      coords[1],
      seriestype=:scatter,
      markersize=10,
      markershape=:star5,
      label="Magazyn",
      xticks=0:10:min(max_x, 100),yticks=0:10:min(max_y, 100),
      xlim=(0, min(max_x, 100)), ylim = (0, min(max_y, 100)),
      size=(800, 800),
      legend=:outerbottom, legendcolumns=3,
      color=:black,
      xtickfontsize=11,ytickfontsize=11,titlefontsize=12,
      xguidefontsize=11,yguidefontsize=11,legendfontsize=12
    )

    save_path::String = split(path, "/")[end]
    save_path = save_path[1:end-5]

    println("> Saving plot in $(save_path)_$(algorithm).svg")

    dir::String = joinpath(@__DIR__, "../../results/plots/")
    (!isdir(dir)) && mkdir(dir)
    savefig(p, dir * "$(save_path)_$(algorithm).svg")
  end # for
end # plot_routes



const solomon_types::Vector{String} = [
  "C1", "C2", "R1", "R2", "RC1", "RC2"
]

const params = Dict(
  "max_it" => (Dict(
      0 => "Maksymalna liczba iteracji",
    ), 3),
  "max_time" => (Dict(
      0 => "Maksymalny czas wykonywania",
    ), 3),
  "no_imp" => (Dict(
      0 => "Maksymalna liczba iteracji bez poprawy",
    ), 3),
  "selection" => (Dict(
      0 => "Selekcja mrówek",
    ), 7),
  "population" => (Dict(
      0 => "Wielkość populacji",
    ), 4),
  "probability" => (Dict(
      0 => "Prawdopodobieństwo wybrania najlepszego klienta \$q_{0}\$",
    ), 5),
  "evaporation" => (Dict(
      0 => "Wartość wyparowywania feromonu \$\\rho\$"
    ), 6),
  "reduction" => (Dict(
      0 => "Znaczenie redukcji okien czasowych"
    ), 8)
)


function read_tuning(folder::String)
  dir::String = joinpath(@__DIR__, "../../results/tuning/" * folder)
  isdir(dir) || return

  if folder ∉ keys(params)
    throw("No such criterion")
  end

  results::Dict = Dict()
  (_, param) = params[folder]

  for file in readdir(dir)
    (data, instance_info) = get_instance_info(file, "tuning", folder)
    if !haskey(results, instance_info[param])
      results[instance_info[param]] = Dict()
    end
    results[instance_info[param]] = data
  end
  plot_tuning(results, folder, dir)
end


function plot_tuning(
  results::Dict,
  folder::String,
  dir::String,
)
  all_keys = sort(collect(keys(results)))
  test_instances = sort(collect(keys(results[all_keys[1]])))[1:end-1]

  plots_data::Dict = Dict()
  for instance in test_instances
    plots_data[instance] = []
    for val in all_keys
      push!(plots_data[instance], results[val][instance]["acs_cost"])
    end
  end # key
  generate_table(plots_data, folder, dir, all_keys)
end


function generate_table(
  plots_data::Dict,
  folder::String,
  dir::String,
  all_keys,
)
  if length(keys(params[folder][1])) == 1
    table_title = params[folder][1][0]
  else 
    table_title = params[folder][1] |> keys |> collect |> sort
  end

  table_lines::Vector{String} = []

  instances = plots_data |> keys |> collect |> sort
  for inst in instances
    max_value = minimum(plots_data[inst])
    line = "$(inst)"
    for i in 1:length(plots_data[inst])
      value = plots_data[inst][i]
      if value == max_value
        line *= rpad(" & \\textbf{$(value)}", 19)
      else
        line *= rpad(" & $(value)", 19)
      end
    end
    line *= " \\\\"
    push!(table_lines, line)
  end

  labels = [
    "instancja",
    all_keys...
  ]

  dir = joinpath(dir, "../../tables/$folder.tex")
  println(dir)
  open(dir, "w") do file
    write(file, "\\begin{table}[H]\n")
    write(file, "    \\centering\n")
    write(file, "        \\caption{$(table_title)}")
    write(file, "\\label{tab:$(replace(table_title, " "=>"_"))}\n")
    write(file, "        \\begin{tabular}{lrrrrrrrrrr}\n")
    write(file, "        \\toprule\n")
    write(file, "        $(join(labels, " & ")) \\\\\n")
    write(file, "        \\midrule\n")

    for row in table_lines
      write(file, "        $row\n")
    end

    write(file, "        \\bottomrule\n")
    write(file, "        \\end{tabular}\n")
    write(file, "\\end{table}\n")
    write(file, "\n\n")
  end
end
