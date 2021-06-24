module Clipping

    using Common
	import Common.AABB
	import Common.getmodel
	using FileManager
	using Printf

	# first include struct
	include("struct.jl")
	include("traversal.jl")
	include("clip.jl")
	include("fileIO.jl")
	include("addpoint.jl")
	#
	# #
	# include("segment/core.jl")
 	# include("slices/main.jl")

	export Common, FileManager
end # module
