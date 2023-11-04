module VRPTWPlots
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
    :cornflowerblue, :maroon1,:orange, :lawngreen,
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


  function plot_routes(
    path::String,
  )::Nothing
    println("Generating plots...")
    (data::Dict, instance_info::Vector) = get_instance_info(path, "routes")

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
      # Depot's coordinates
      p = plot(
        coords[1],
        seriestype=:scatter,
        markersize=10,
        markershape=:star5,
        label="Depot",
        xticks=0:10:min(max_x, 100),yticks=0:10:min(max_y, 100),
        xlim=(0, min(max_x, 100)), ylim = (0, min(max_y, 100)),
        size=(800, 800),
        legend=:outerbottom, legendcolumns=3,
        color=:black
      )

      # Customers' coordinates
      plot!(
        coords[2:end],
        seriestype=:scatter,
        markersize=4,
        markershape=:hexagon,
        label="Customers",
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
          GR.setarrowsize(0.5),
          arrow=Plots.Arrow(:closed, :head, 0.1, 0.1),
          linewidth=1,
          title="$(instance_info[1]) with $(instance_info[2]) customers \
          using $(algorithm) algorithm, \
          cost=$(trunc(data[algorithm]["cost"], digits=3))",
          label="",
          color=color_palette[i],
        )
        plot!([], [], label="Route $i", color=color_palette[i])
      end

      save_path::String = split(path, "/")[end]
      save_path = save_path[1:end-5]

      println("> Saving plot in $(save_path)_$(algorithm).svg")

      dir::String = joinpath(@__DIR__, "../../results/plots/")
      (!isdir(dir)) && mkdir(dir)
      savefig(p, dir * "$(save_path)_$(algorithm).svg")
    end # for
  end # plot_routes


  function get_instance_info(
    path::String,
    plot_type::String
  )::Tuple{Dict, Vector}
    dir::String = "../../results/"
    if plot_type == "routes"
      dir = dir * "coords/"
    end

    dir = joinpath(@__DIR__, dir * path)
    if !isfile(dir)
      throw("File $path does not exist")
    end

    data::Dict = JSON.parsefile(
      dir,
      dicttype=Dict
    )

    parameters::Vector{String} = split(path, "-")
    if length(parameters) < 4
      throw("File $path does not contain instance parameters")
    end

    instance_info = [
      split(parameters[1], "/")[end], # name
      parse(Int, parameters[2][2:end]), # no_customers
      parse(Int, parameters[3][2:end]), # no_vehicles
      parse(Int, parameters[4][2:end]), # capacity
    ]

    return (data, instance_info)
  end

end # VRPTWPlots
