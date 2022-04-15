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
