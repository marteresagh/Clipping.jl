"""
	get_potree_dirs(txtpotreedirs::String)

Return collection of potree directories.
"""
function get_potree_dirs(txtpotreedirs::String)
    if isfile(txtpotreedirs)
    	return FileManager.readlines(txtpotreedirs)
    elseif isdir(txtpotreedirs)
    	return [txtpotreedirs]
    end
end


"""
Save point cloud extracted file .las.
"""
function savepointcloud(
	params::ParametersClipping,
	temp::String
	)

	flushprintln("Point cloud: saving ...")

	# update header metadata
	params.mainHeader.records_count = params.numPointsProcessed # update number of points in header

	#update header bounding box
	flushprintln("Point cloud: update bbox ...")
	params.mainHeader.x_min = params.tightBB.x_min
	params.mainHeader.y_min = params.tightBB.y_min
	params.mainHeader.z_min = params.tightBB.z_min
	params.mainHeader.x_max = params.tightBB.x_max
	params.mainHeader.y_max = params.tightBB.y_max
	params.mainHeader.z_max = params.tightBB.z_max

	# write las file
	pointtype = LasIO.pointformat(params.mainHeader) # las point format


	if params.mainHeader.records_count != 0 # if n == 0 nothing to save
		# in temp : list of las point records
		open(temp, "r") do s
			# write las
			open(params.outputfile,"w") do t
				write(t, LasIO.magic(LasIO.format"LAS"))
				write(t,params.mainHeader)

				for i = 1:params.mainHeader.records_count
					p = read(s, pointtype)
					write(t,p)
				end
			end
		end
	end

	rm(temp) # remove temp
	flushprintln("Point cloud: done ...")
end



function newPointRecord(point::Point, type::LasIO.DataType, header::LasIO.LasHeader)

	x = LasIO.xcoord(point.position[1], header)
	y = LasIO.ycoord(point.position[2], header)
	z = LasIO.zcoord(point.position[3], header)
	intensity = UInt16(0)
	flag_byte = UInt8(0)
	raw_classification = UInt8(0)
	scan_angle = Int8(0)
	user_data = UInt8(0)
	pt_src_id = UInt16(0)

	if type == LasIO.LasPoint0
		return type(x, y, z,
					intensity, flag_byte, raw_classification,
					scan_angle, user_data, pt_src_id
					)

	elseif type == LasIO.LasPoint1
		gps_time = Float64(0)
		return type(x, y, z,
					intensity, flag_byte, raw_classification,
					scan_angle, user_data, pt_src_id, gps_time
					)

	elseif type == LasIO.LasPoint2
		red = point.color[1]
		green = point.color[2]
		blue = point.color[3]
		return type(x, y, z,
					intensity, flag_byte, raw_classification,
					scan_angle, user_data, pt_src_id,
					red, green, blue
					)

	elseif type == LasIO.LasPoint3
		gps_time = Float64(0)
		red = rgb[1]
		green = rgb[2]
		blue = rgb[3]
		return type(x, y, z,
					intensity, flag_byte, raw_classification,
					scan_angle, user_data, pt_src_id, gps_time,
					red, green, blue
					)

	end

end



"""
	PO2matrix(PO::String, UCS=Matrix{Float64}(Common.I,4,4)::Matrix)

Observation point.
Valid input:
 - "XY+": Top view
 - "XY-": Bottom view
 - "XZ+": Back view
 - "XZ-": Front view
 - "YZ+": Left view
 - "YZ-": Right view
"""
function PO2matrix(PO::String, UCS=Matrix{Float64}(Common.I,4,4)::Matrix)
    planecode = PO[1:2]
    @assert planecode == "XY" || planecode == "XZ" || planecode == "YZ" "orthoprojectionimage: $PO not valid view "

    directionview = PO[3]
    @assert directionview == '+' || directionview == '-' "orthoprojectionimage: $PO not valid view "

    coordsystemmatrix = Matrix{Float64}(Common.I,3,3)

    # if planecode == XY # top, - bottom
    #     continue
    if planecode == "XZ" # back, - front
        coordsystemmatrix[1,1] = -1.
        coordsystemmatrix[2,2] = 0.
        coordsystemmatrix[3,3] = 0.
        coordsystemmatrix[2,3] = 1.
        coordsystemmatrix[3,2] = 1.
    elseif planecode == "YZ" # right, - left
        coordsystemmatrix[1,1] = 0.
        coordsystemmatrix[2,2] = 0.
        coordsystemmatrix[3,3] = 0.
        coordsystemmatrix[1,2] = 1.
        coordsystemmatrix[2,3] = 1.
        coordsystemmatrix[3,1] = 1.
    end

    # if directionview == "+"
    #     continue
    if directionview == '-'
        R = [-1. 0 0; 0 1. 0; 0 0 -1]
        coordsystemmatrix = R*coordsystemmatrix
    end

    return coordsystemmatrix*UCS[1:3,1:3]
end
