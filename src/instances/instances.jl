module Instances
  include("../instances/types.jl")
  export Instance, Customer

  include("./file_parser.jl")
  export read_instance
  export write_results, write_latex_table
  export dict_to_json, get_instance_info

  include("./preprocessing.jl")
  export reduce_instance_windows

  include("./plotting.jl")
  export plot_routes, read_tuning

  include("./prd.jl")
  export plot_prd
end

using .Instances