println("loading packages... ")

using ArgParse
using Clipping

println("packages OK")

function parse_commandline()
    s = ArgParseSettings()

    @add_arg_table! s begin
		"--output", "-o"
            help = "Output file: LAS format"
			required = true
        "source"
            help = "A text file with Potree directories list or a single Potree directory"
            required = true
		"--bbox"
			help = "Bounding box as 'x_min y_min z_min x_max y_max z_max'"
			arg_type = String
		"--jsonfile"
	    	help = "Path to Potree JSON volume model"
			arg_type = String
		"--position","-c"
			help = "Position: center of volume"
			arg_type = String
		"--scale","-e"
			help = "Scale: size of box"
			arg_type = String
		"--rotation","-r"
			help = "Rotation: Euler angles (radians) of rotation of box"
			arg_type = String
		"--epsg"
			help = "EPSG code"
			arg_type = Int
    end

    return parse_args(s)
end

function main()
	args = parse_commandline()

	bbox = args["bbox"]
	jsonfile = args["jsonfile"]
	position_ = args["position"]
	scale_ = args["scale"]
	rotation_ = args["rotation"]
	output = args["output"]
	txtpotreedirs = args["source"]
	epsg = args["epsg"]

	println("== params ==")
	println(" Sources => $txtpotreedirs ")
	println(" Output => $output ")
	if !isnothing(epsg)
		println(" EPSG => $epsg ")
	end
	println(" ")

	model = nothing

	if !isnothing(bbox)
		b = tryparse.(Float64,split(bbox, " "))
		@assert length(b) == 6 "Required bounding box as 'x_min y_min z_min x_max y_max z_max'"
		bbox = Clipping.AABB(b[4],b[1],b[5],b[2],b[6],b[3])
		println(" Bounding Box => $bbox ")
		model = Clipping.getmodel(bbox)
	elseif !isnothing(jsonfile)
		println(" Volume => $jsonfile ")
		model = Clipping.getmodel(jsonfile)
	else
		scale = tryparse.(Float64,split(scale_, " "))
		@assert length(scale) == 3 "a 3D vector needed"
		position = tryparse.(Float64,split(position_, " "))
		@assert length(position) == 3 "a 3D vector needed"
		rotation = tryparse.(Float64,split(rotation_, " "))
		@assert length(rotation) == 3 "a 3D vector needed"

		println(" Position => $position ")
		println(" Scale => $scale ")
		println(" Rotation => $rotation ")

		volume = Clipping.Volume(scale,position,rotation)
		model = Clipping.getmodel(volume)
	end

	println(" ")
	flush(stdout)

	Clipping.clip(txtpotreedirs, output, model, epsg)
end

@time main()
