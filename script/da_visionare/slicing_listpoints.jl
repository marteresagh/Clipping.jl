println("loading packages... ")

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
	"--listpoints"
		help = "A text file containing a list of two points."
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
	file_listpoints = args["listpoints"]
	axis_ = args["axis"]
	thickness = args["thickness"]

	b = tryparse.(Float64,split(bbin, " "))
	if length(b) == 6
		bbin = OrthographicProjection.AABB(b[4],b[1],b[5],b[2],b[6],b[3])
	end
	
	axis_y = tryparse.(Float64,split(axis_, " "))
	@assert length(axis_y) == 3 "a 3D axis needed"

	proj_folder, models = OrthographicProjection.preprocess(project_name, output_folder, bbin, file_listpoints, axis_y, thickness)
	OrthographicProjection.extract_models(txtpotreedirs, project_name, proj_folder, bbin, models)

end

@time main()
