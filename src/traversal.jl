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
