Generated cache files

This folder contains generated artifacts that speed up local road-distance
calculation and map rendering:

- road_distances/: validated candidate-to-candidate distance matrices.
- road_graphs/: clipped road graph caches built from the local shapefile.
- map_overlays/: clipped road overlays used by the geographic map.

These files can be deleted safely. They will be regenerated when needed.
