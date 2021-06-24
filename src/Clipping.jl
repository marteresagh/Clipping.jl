module Clipping

    using Common
	import Common.AABB
	import Common.getmodel
	using FileManager

	# first include struct
	include("struct.jl")
	include("traversal.jl")
	include("clip.jl")
	include("fileIO.jl")
	include("addpoint.jl")
 	# include("slices/main.jl")

	export Common, FileManager
end # module
