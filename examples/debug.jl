using Clipping
using FileManager
using Common
using Visualization

potree = "C:/Users/marte/Documents/potreeDirectory/pointclouds/CAVA"
output = "examples/prova.las"
metadata = CloudMetadata(potree)
bbin = metadata.tightBoundingBox
#bbin = "C:/Users/marte/Documents/GEOWEB/wrapper_file/JSON/volume_COLOMBELLA.json"
# bbin = AABB(1,0,1,0,1,0)
model = FileManager.getmodel(bbin)
epsg = nothing
# Clipping.traversal(potree,model,println)
Clipping.segment(potree, output, model, epsg)


# params = Clipping.ParametersClipping(potree, output, model, epsg)
