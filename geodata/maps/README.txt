Local Bangladesh road data
==========================

The project uses the MATLAB-readable road shapefile:

    bangladesh_roads.shp

Keep all companion shapefile files in this folder, including `.dbf`, `.shx`,
and `.prj` files if they were provided with the download.

The MATLAB Mapping Toolbox reads the road polylines directly, builds a local
road graph, and computes shortest-path distances. No Python conversion and no
online routing service are required.

Generated road graph caches are stored in the root-level
`cache/road_graphs/` directory.
