
function addWithControl(params::ParametersClipping)
    function addWithControl0(file::String)
        header, laspoints = FileManager.read_LAS_LAZ(file) # read file
        for laspoint in laspoints # read each point
            #point = FileManager.xyz(laspoint, header)
            point = Point(laspoint, header)
            if Common.inmodel(params.model)(point.position) # if point in model
                add_point(params, point)
            end
        end
    end
    return addWithControl0
end


function addWithoutControl(params::ParametersClipping)
    function addWithoutControl0(file::String)
        header, laspoints = FileManager.read_LAS_LAZ(file) # read file
        for laspoint in laspoints # read each point
            point = Point(laspoint, header)
            add_point(params, point)
        end
    end
    return addWithoutControl0
end

function add_point(
    params::ParametersClipping,
    point::Point
)
    Common.update_boundingbox!(params.tightBB,point.position)
    plas = newPointRecord(point, LasIO.LasPoint2, params.mainHeader)
    params.numPointsProcessed = params.numPointsProcessed + 1
    write(params.stream_tmp, plas)

end
