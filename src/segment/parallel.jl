# """
# 	get_sections(
# 		txtpotreedirs::String,
# 		project_name::String,
# 		proj_folder::String,
# 		bbin::Union{AABB,String},
# 		models::Array{LAR,1})
#
# For each model in models extracts and saves the clipped point cloud.
# """
# function extract_models(
# 	txtpotreedirs::String,
# 	project_name::String,
# 	proj_folder::String,
# 	bbin::Union{AABB,String},
# 	models::Array{LAR,1})
#
# 	n_models = length(models)
# 	Threads.@threads for i in 1:n_models
# 		flushprintln(" ")
# 		flushprintln(" ---- Section $i of $n_models ----")
# 		output = joinpath(proj_folder,project_name)*"_section_$(i-1).las"
# 		segment(txtpotreedirs, output, models[i]; temp_name = "temp_$i.las") # slicing point cloud
# 	end
# end
