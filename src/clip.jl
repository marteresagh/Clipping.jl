function clip(
    txtpotreedirs::String,
    output::String,
    model::Common.LAR,
    epsg::Union{Nothing,Integer};
    tmp_las = "tmp.las"::String,
)
    # initialize parameters

    params = ParametersClipping(txtpotreedirs, output, model, epsg)

    proj_folder = splitdir(params.outputfile)[1]

    temp = joinpath(proj_folder, tmp_las)
    params.stream_tmp = open(temp, "w")

    for potree in params.potreedirs
        params.numFilesProcessed = 0
        traversal(potree, params)
    end

    close(params.stream_tmp)

    println("Processed $(params.numPointsProcessed) points")
    savepointcloud(params, temp)
    return params.numPointsProcessed != 0
end
