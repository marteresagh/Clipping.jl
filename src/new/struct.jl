mutable struct ClippingArguments
	destinationDir::String
	filename::String
	potreedirs::Vector{String}
	model::Common.LAR
	tightBB::AABB
	numPointsProcessed::Int64
	numNodes::Int64
	currentNumFilesProcessed::Int64
	mainHeader::LasIO.LasHeader
	stream_tmp::Union{Nothing,IOStream}

	# parametri che passa l'utente
	function ClippingArguments(
		destinationDir::String,
		potrees::Vector{String},
		filename::String,
		model::Common.LAR,
		epsg::Union{Nothing,Integer})

		numPointsProcessed = 0
		numNodes = 0
		numFilesProcessed = 0

		aabb = AABB(model[1])
		mainHeader = FileManager.newHeader(aabb,"CLIPPING",FileManager.SIZE_DATARECORD)

		if !isnothing(epsg)
			FileManager.LasIO.epsg_code!(mainHeader, epsg)
		end

		stream_tmp = nothing

		return new(destinationDir,
					filename,
					potrees,
					model,
					AABB(-Inf, Inf,-Inf, Inf,-Inf, Inf),
					numPointsProcessed,
					numNodes,
					numFilesProcessed,
					mainHeader,
					stream_tmp)
	end

end
