"""
preprocess(
	project_name::String,
	output_folder::String,
	bbin::Union{AABB,String},
	plane::Plane,
	thickness::Float64
	)

Create project folder and create LAR model of thickness plane described in Hessian normal form.
"""
function preprocess(
	project_name::String,
	output_folder::String,
	bbin::Union{AABB,String},
	plane::Plane,
	thickness::Float64
	)

	proj_folder = FileManager.mkdir_project(output_folder, project_name)
	model = Common.getmodel(plane, thickness, bbin)

	return proj_folder,model
end

"""
preprocess(
	project_name::String,
	output_folder::String,
	bbin::Union{AABB,String},
	p1::Array{Float64,1},
	p2::Array{Float64,1},
	axis_y::Array{Float64,1},
	thickness::Float64
	)

Create project folder and create LAR model of thickness plane described by two points and a vector in plane.
"""
function preprocess(
	project_name::String,
	output_folder::String,
	bbin::Union{AABB,String},
	p1::Array{Float64,1},
	p2::Array{Float64,1},
	axis_y::Array{Float64,1},
	thickness::Float64
	)

	proj_folder = FileManager.mkdir_project(output_folder, project_name)
	axis = (p2-p1)/Common.norm(p2-p1)
	axis_y /= Common.norm(axis_y)
	axis_z = Common.cross(axis,axis_y)
	FileManager.successful(axis_z != [0.,0.,0.], proj_folder)
	plane = Plane(p1,p2,axis_y)
	model = Common.getmodel(p1,p2,axis_y,thickness,bbin)

	return proj_folder, plane, model
end



"""
preprocess(
	project_name::String,
	output_folder::String,
	bbin::Union{AABB,String},
	file_listpoints::String,
	axis_y::Array{Float64,1},
	thickness::Float64
	)

Create project folder and create LAR models of thickness planes described by two points (read in file) and a vector in plane.
"""
function preprocess(
	project_name::String,
	output_folder::String,
	bbin::Union{AABB,String},
	file_listpoints::String,
	axis_y::Array{Float64,1},
	thickness::Float64
	)

	proj_folder = FileManager.mkdir_project(output_folder, project_name)
	V,EVs = FileManager.load_segment(file_listpoints)

	models = Common.LAR[]

	for EV in EVs
		try
			model = Common.getmodel(V[:,EV[1]],V[:,EV[2]],axis_y,thickness,bbin)
			push!(models,model)
		catch y
			# flushprintln("ERROR: Plane not consistent")
			# io = open(joinpath(proj_folder,"process.prob"),"w")
			# close(io)
		end
	end

	return proj_folder, models
end

"""
get_parallel_sections(
	txtpotreedirs::String,
	project_name::String,
	proj_folder::String,
	bbin::Union{AABB,String},
	step::Float64,
	plane::Plane,
	model::Common.LAR)

Return parallel sections of point cloud.

Input:
 - A text file containing a list of files to segment
 - Project name
 - A folder for saving results
 - A box model: region of interest
 - Distance between slices
 - Plane description of first slice
 - LAR model of thickness plane

Output:
 - A file .las for each slice
"""
function get_parallel_sections(
	txtpotreedirs::String,
	project_name::String,
	proj_folder::String,
	bbin::Union{AABB,String},
	step::Float64,
	plane::Plane,
	model::Common.LAR)

	V,EV,FV = model # first plane

	quotas, indices = get_quotas(plane, step, bbin) # quota and indices of each slice

	planes = Common.LAR[]
	n_sections = length(indices)
	Threads.@threads for i in 1:n_sections
		flushprintln(" ")
		flushprintln(" ---- Section $i of $n_sections ----")
		T = Common.apply_matrix(Common.t(Common.inv(plane.matrix)[1:3,3]*indices[i]*step...),V) # traslate model
		plan = (T,EV,FV) # new model
		push!(planes,plan)
		output = joinpath(proj_folder,project_name)*"_section_$(indices[i]).las"
		segment(txtpotreedirs, output, plan; temp_name = "temp_$i.las") # slicing point cloud
	end

	return planes
end

function get_parallel_sections(
	txtpotreedirs::String,
	project_name::String,
	proj_folder::String,
	bbin::Union{AABB,String},
	steps::Array{Float64,1},
	plane::Plane,
	model::Common.LAR)

	V,EV,FV = model # first plane
	planes = Common.LAR[]
	n_sections = length(steps)

	Threads.@threads for i in 1:n_sections
		flushprintln(" ")
		flushprintln(" ---- Section $i of $(n_sections) ----")
		T = Common.apply_matrix(Common.t(-Common.inv(plane.matrix)[1:3,3]*sum(steps[1:i])...),V) # traslate model
		plan = (T,EV,FV) # new model
		push!(planes,plan)
		output = joinpath(proj_folder,project_name)*"_section_$(i-1).las"
		segment(txtpotreedirs, output, plan; temp_name = "temp_$i.las") # slicing point cloud
	end

	return planes
end

"""
Return quotas and indices of each LAR model thickness plane.
"""
function get_quotas(plane::Plane, step::Float64,  bbin::Union{AABB,String})

	model = getmodel(bbin)
	normal = [plane.a,plane.b,plane.c]
	V = model[1]
	dists = [Common.dot(normal, V[:,i]) for i in 1:size(V,2)]
	min,max = extrema(dists)
	quota = min+modf((plane.d-min)/step)[1]*step
	quotas = Float64[]

	if step > 0
		while quota <= max
			push!(quotas,quota)
			quota = quota+step
		end
		ind_0 = findall(x->x==plane.d,quotas)[1]

		return quotas, [-(ind_0-1):(length(quotas)-ind_0)...]
	elseif step == 0
		return plane.d, [0]
	else
		while quota <= max
			push!(quotas,quota)
			quota = quota+(-step)
		end
		ind_0 = findall(x->x==plane.d,quotas)[1]

		return quotas, [-(length(quotas)-ind_0):(ind_0-1)...]
	end

end
