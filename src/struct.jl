"""
	Point

Point information.

# Constructors
```jldoctest
Point(lasPoint::FileManager.LasPoint, header::FileManager.LasHeader)::Point
```

# Fields
```jldoctest
position::Vector{Float64}
color::Vector{UInt16}
normal::Vector{Float64}
intensity::UInt16
classification::Char
returnNumber::Char
numberOfReturns::Char
pointSourceID::UInt16
gpsTime::Float64
```
"""
struct Point
	position::Vector{Float64}
	color::Vector{LasIO.FixedPointNumbers.N0f16}
	normal::Vector{Float64}
	intensity::UInt16
	classification::Char
	returnNumber::Char
	numberOfReturns::Char
	pointSourceID::UInt16
	gpsTime::Float64



	function Point(lasPoint::FileManager.LasPoint, header::FileManager.LasHeader)::Point
	    position = FileManager.xyz(lasPoint,header)
		color = [lasPoint.red,lasPoint.green,lasPoint.blue]
		normal = Float64[]
		intensity = lasPoint.intensity
		classification = lasPoint.raw_classification
		returnNumber = 0
		numberOfReturns = 0
		pointSourceID = lasPoint.pt_src_id
		gpsTime = 0.0
		return new(position,
					color,
					normal,
					intensity,
					classification,
					returnNumber,
					numberOfReturns,
					pointSourceID,
					gpsTime,)
	end

end

function Base.show(io::IO, point::Point)
    println(io, "position: $(point.position)")
	println(io, "color: $(point.color)")
end



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
