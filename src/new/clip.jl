function clip(
    destinationDir::String,
    potrees::Vector{String},
    filename::String,
    model::Common.LAR;
    epsg = nothing::Union{Nothing,Integer},
    tmp_las = "tmp.las"::String,
)
    # initialize parameters
    params = ClippingArguments(destinationDir, potrees, filename, model, epsg)

    temp = joinpath(destinationDir, tmp_las)
    params.stream_tmp = open(temp, "w")

    for potree in params.potreedirs
        params.currentNumFilesProcessed = 0
        traversal(potree, params)
    end

    close(params.stream_tmp)

    println("Processed $(params.numPointsProcessed) points")

    if params.numPointsProcessed > 0
        savepointcloud(params, temp)
    end

    rm(temp)

    return params
end



"""
Save point cloud extracted file .las.
"""
function savepointcloud(params::ClippingArguments, temp::String)

    println("Point cloud: saving ...")

    # update header metadata
    params.mainHeader.records_count = params.numPointsProcessed # update number of points in header

    #update header bounding box
    println("Point cloud: update bbox ...")
    params.mainHeader.x_min = params.tightBB.x_min
    params.mainHeader.y_min = params.tightBB.y_min
    params.mainHeader.z_min = params.tightBB.z_min
    params.mainHeader.x_max = params.tightBB.x_max
    params.mainHeader.y_max = params.tightBB.y_max
    params.mainHeader.z_max = params.tightBB.z_max

    # write las file
    pointtype = LasIO.pointformat(params.mainHeader) # las point format

    # in temp : list of las point records
    open(temp, "r") do s
        # write las
        open(joinpath(params.destinationDir, params.filename), "w") do t
            write(t, LasIO.magic(LasIO.format"LAS"))
            write(t, params.mainHeader)

            for i = 1:params.mainHeader.records_count
                p = read(s, pointtype)
                write(t, p)
                if i % 10000 == 0
                    flush(t)
                end
            end
        end
    end

    println("Point cloud: done ...")
end
