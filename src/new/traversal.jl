function traversal(potree::String, params::ClippingArguments)
	println("= ")
	println("= PROJECT: $potree")
	println("= ")

	metadata = CloudMetadata(potree) # metadata of current potree project
	trie = potree2trie(potree)
	params.numNodes = length(keys(trie))
	# if model contains the whole point cloud ( == 2)
	#	process all files
	# else
	# 	navigate potree

	intersection = Common.modelsdetection(params.model, metadata.tightBoundingBox)

	if intersection == 2
		println("FULL model")
		for k in keys(trie)
			params.currentNumFilesProcessed += 1
			if params.currentNumFilesProcessed%100==0
				println(params.currentNumFilesProcessed," files processed of ",params.numNodes)
			end

			file = trie[k]
			addWithoutControl(params)(file)

		end
	elseif intersection == 1
		println("DFS")
		dfs(trie,params)

		if params.numNodes-params.currentNumFilesProcessed > 0
			println("$(params.numNodes-params.currentNumFilesProcessed) file of $(params.numNodes) not processed - out of region of interest")
		end
	elseif intersection == 0
		println("OUT OF REGION OF INTEREST")
	end

end



"""
	dfs(trie::DataStructures.Trie{String}, model::Common.LAR)# due callback: 1 con controllo e 1 senza controllo
Depth search first.
"""
function dfs(trie::DataStructures.Trie{String}, params::ClippingArguments)# due callback: 1 con controllo e 1 senza controllo

	file = trie.value # path to node file
	nodebb = FileManager.las2aabb(file) # aabb of current octree
	inter = Common.modelsdetection(params.model, nodebb)

	if inter == 1
		# intersecato ma non contenuto
		# alcuni punti ricadono nel modello altri no
		params.currentNumFilesProcessed += 1
		if params.currentNumFilesProcessed%100==0
			println(params.currentNumFilesProcessed, " files processed of ", params.numNodes)
		end

		addWithControl(params)(file) # update with check
		for key in collect(keys(trie.children)) # for all children
			dfs(trie.children[key],params)
		end
	elseif inter == 2
		# contenuto: tutti i punti del albero sono nel modello
		for k in keys(trie)
			params.currentNumFilesProcessed += 1
			if params.currentNumFilesProcessed%100==0
				println(params.currentNumFilesProcessed, " files processed of ", params.numNodes)
			end
			file = trie[k]
			addWithoutControl(params)(file) # update without check
		end
	end

end



function addWithControl(params::ClippingArguments)
    function addWithControl0(file::String)
        header, laspoints = FileManager.read_LAS_LAZ(file) # read file
        for laspoint in laspoints # read each point
            point = Point(laspoint, header)
            if Common.inmodel(params.model)(point.position) # if point in model
                add_point(params, point)
            end
        end
    end
    return addWithControl0
end


function addWithoutControl(params::ClippingArguments)
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
    params::ClippingArguments,
    point::Point
)
    Common.update_boundingbox!(params.tightBB,point.position)
    plas = newPointRecord(point, LasIO.LasPoint2, params.mainHeader)
    params.numPointsProcessed = params.numPointsProcessed + 1
    write(params.stream_tmp, plas)

end
