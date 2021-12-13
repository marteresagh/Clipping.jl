println("loading packages... ")

using ArgParse
using Clipping

println("packages OK")

function parse_commandline()
    s = ArgParseSettings()

    @add_arg_table! s begin
        "source"
            help = "A text file with Potree directories list or a single Potree directory"
            arg_type = String
            required = true
        "--projectname", "-p"
            help = "Project name"
            arg_type = String
            required = true
        "--output", "-o"
            help = "Output folder"
            arg_type = String
            required = true
        "--bbin"
            help = "Bounding box as 'x_min y_min z_min x_max y_max z_max' or Potree JSON volume model"
            required = true
        "--p1"
            help = "Start point"
            arg_type = String
            required = true
        "--p2"
            help = "End point"
            arg_type = String
            required = true
        "--axis"
            help = "A vector in plane"
            arg_type = String
            default = "0 0 1"
        "--thickness"
            help = "Section thickness"
            arg_type = Float64
            default = 0.1
        "--step"
            help = "Constant distance between sections"
            arg_type = Float64
        "--n"
            help = "Number of sections"
            arg_type = Int64
        "--steps"
            help = "Distance between sections"
            arg_type = String
    end

    return parse_args(s)
end

function main()
    args = parse_commandline()

    txtpotreedirs = args["source"]
    project_name = args["projectname"]
    output_folder = args["output"]
    bbin = args["bbin"]
    steps = args["steps"]
    step = args["step"]
    n = args["n"]
    p1_ = args["p1"]
    p2_ = args["p2"]
    axis_ = args["axis"]
    thickness = args["thickness"]

    b = tryparse.(Float64, split(bbin, " "))
    if length(b) == 6
        bbin = Clipping.AABB(b[4], b[1], b[5], b[2], b[6], b[3])
    end

    p1 = tryparse.(Float64, split(p1_, " "))
    @assert length(p1) == 3 "a 3D point needed"
    p2 = tryparse.(Float64, split(p2_, " "))
    @assert length(p2) == 3 "a 3D point needed"
    axis_y = tryparse.(Float64, split(axis_, " "))
    @assert length(axis_y) == 3 "a 3D axis needed"

    if !isnothing(step) && !isnothing(n)
        steps = fill(step, n)
    elseif !isnothing(steps)
        steps = tryparse.(Float64, split(steps, " "))
    else
        steps = Float64[]
    end

    prepend!(steps, 0.0)

    println("== params ==")
	println(" Sources => $txtpotreedirs ")
    println(" Bounding Box => $bbin ")
	println(" Output => $output_folder ")
	println(" Project name => $project_name ")
	println(" Steps => $steps ")
	println(" Plane => p1: $p1, p2: $p2, up: $axis_y  ")
	println(" Thickness => $thickness ")
	println(" ")
	flush(stdout)

    proj_folder = FileManager.mkdir_project(output_folder, project_name)

    axis = (p2 - p1) / Common.norm(p2 - p1)
    axis_y = Common.normalize(axis_y)
    axis_z = Common.cross(axis, axis_y)

    @assert axis_z != [0.0, 0.0, 0.0] "no consistent plane"

    V, EV, FV = Common.getmodel(p1, p2, axis_y, thickness, bbin)

    plane = Clipping.Plane(p1, p2, axis_y)
    # altitudes, indices = Clipping.get_altitudes(plane, step, bbin) # altitudes and indices of each slice

    n_sections = length(steps)

    Threads.@threads for i = 1:n_sections
        println(" ")
        println(" ---- Section $i of $(n_sections) ----")
        T = Common.apply_matrix(
            Common.t(-Common.inv(plane.matrix)[1:3, 3] * sum(steps[1:i])...),
            V,
        ) # traslate model
        plan = (T, EV, FV) # new model
        output = joinpath(proj_folder, project_name) * "_section_$(i-1).las"
        Clipping.clip(txtpotreedirs, output, plan, nothing; tmp_las = "temp_$i.las") # slicing point cloud
    end



end

@time main()
