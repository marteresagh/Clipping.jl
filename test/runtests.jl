using Clipping
using Test

@testset "init" begin
	outfile = "outfile.las"
	V = [ 0.0  0.0  0.0  0.0  1.0  1.0  1.0  1.0;
		  0.0  0.0  1.0  1.0  0.0  0.0  1.0  1.0;
		  0.0  1.0  0.0  1.0  0.0  1.0  0.0  1.0]
	CV = [[1, 2, 3, 4, 5, 6, 7, 8]]
	model = (V,CV)
	params = OrthographicProjection.ParametersClipping(joinpath(workdir,filename), outfile, model, nothing)

	@test typeof(params) == OrthographicProjection.ParametersExtraction
	@test params.outputfile == outfile
	@test params.model == model
	@test typeof(params.mainHeader) == OrthographicProjection.LasIO.LasHeader
	AABB = OrthographicProjection.FileManager.las2aabb(params.mainHeader)
	@test AABB.x_max == 1.0
	@test AABB.x_min == 0.0
	@test AABB.y_max == 1.0
	@test AABB.y_min == 0.0
	@test AABB.z_max == 1.0
	@test AABB.z_min == 0.0
end
