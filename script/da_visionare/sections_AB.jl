println("loading packages... ")
# Parallele per tutto il bbin
using ArgParse
using OrthographicProjection

println("packages OK")

function parse_commandline()
	s = ArgParseSettings()

	@add_arg_table! s begin
	"source"
		help = "A text file with Potree directory list"
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
	"--step"
		help = "Distance between sections"
		arg_type = Float64
		default = 0.
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
	end

	return parse_args(s)
end

function main()
	args = parse_commandline()

	OrthographicProjection.flushprintln("== params ==")
	for (arg,val) in args
		OrthographicProjection.flushprintln("$arg  =>  $val")
	end

	txtpotreedirs = args["source"]
	project_name = args["projectname"]
	output_folder = args["output"]
	bbin = args["bbin"]
	step = args["step"]
	p1_ = args["p1"]
	p2_ = args["p2"]
	axis_ = args["axis"]
	thickness = args["thickness"]


	# p = tryparse.(Float64,split(plane, " "))
	# @assert length(p) == 4 "$plane: Please described the plane in Hessian normal form"
	# plane = OrthographicProjection.Plane(p[1],p[2],p[3],p[4])


	b = tryparse.(Float64,split(bbin, " "))
	if length(b) == 6
		bbin = OrthographicProjection.AABB(b[4],b[1],b[5],b[2],b[6],b[3])
	end

	p1 = tryparse.(Float64,split(p1_, " "))
	@assert length(p1) == 3 "a 3D point needed"
	p2 = tryparse.(Float64,split(p2_, " "))
	@assert length(p2) == 3 "a 3D point needed"
	axis_y = tryparse.(Float64,split(axis_, " "))
	@assert length(axis_y) == 3 "a 3D axis needed"

	try
		proj_folder, plane, model = OrthographicProjection.preprocess(project_name, output_folder, bbin, p1, p2, axis_y, thickness)
		OrthographicProjection.get_parallel_sections(txtpotreedirs, project_name, proj_folder, bbin, step, plane, model)
	catch y

	end

end

@time main()
