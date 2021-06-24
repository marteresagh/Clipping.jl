println("loading packages... ")

using ArgParse
using OrthographicProjection

println("packages OK")

function parse_commandline()
    s = ArgParseSettings()

    @add_arg_table! s begin
		"source"
			help = "A text file with Potree directories list or a single Potree directory"
			required = true
		"--output", "-o"
            help = "Output file"
			required = true
		"--bbin"
            help = "Bounding box as 'x_min y_min z_min x_max y_max z_max' or Potree JSON volume model"
			required = true
		"--po"
            help = "Projection plane: XY+, XZ+, YZ+"
			arg_type = String
            default = "XY+"
		"--quote"
			help = "Distance of plane from origin"
			arg_type = Float64
		"--thickness"
			help = "Section thickness"
			arg_type = Float64
		"--ucs"
			help = "Path to UCS JSON file. If not provided is the identity matrix"
			arg_type = String
		"--epsg"
			help = "EPSG code"
			arg_type = Int
    end

    return parse_args(s)
end

function main()
    args = parse_commandline()


	OrthographicProjection.flushprintln("== params ==")
    for (arg,val) in args
        OrthographicProjection.flushprintln("$arg  =>  $val")
    end

	bbin = args["bbin"]
	output = args["output"]
	PO = args["po"]
	txtpotreedirs = args["source"]
	q = args["quote"]
	thickness = args["thickness"]
	ucs = args["ucs"]
	epsg = args["epsg"]

	b = tryparse.(Float64,split(bbin, " "))
	if length(b) == 6
		#bbin = (hcat([b[1],b[2],b[3]]),hcat([b[4],b[5],b[6]]))
		bbin = Common.AABB(b[4],b[1],b[5],b[2],b[6],b[3])
	end

	if isnothing(ucs)
		ucs = Matrix{Float64}(Common.I,4,4)
	else
		ucs = FileManager.ucs2matrix(ucs)
	end


	coordsystemmatrix = OrthographicProjection.PO2matrix(PO,ucs)
	model = Common.getmodel(bbin)
	aabb = Common.boundingbox(model[1])

	if !isnothing(q) && !isnothing(thickness)
		origin = Common.inv(ucs)[1:3,4]
		model = Common.getmodel(Common.inv(coordsystemmatrix), q, thickness, aabb; new_origin = origin)
	end

	seg = OrthographicProjection.segment(txtpotreedirs, output, model; epsg = epsg)
	proj_folder = splitdir(output)[1]
	FileManager.successful(seg, proj_folder)
end

@time main()
