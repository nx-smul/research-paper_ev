# EV Charging Station Optimization in MATLAB

This project selects suitable EV charging-station locations using a
budget-constrained Maximal Covering Location Problem (MCLP). The current
example uses candidate locations in Dhaka, Bangladesh.

The model considers:

- car demand,
- electric-motorcycle demand,
- population density,
- site cost,
- distance between candidate sites,
- charger installation cost,
- service radius,
- station limit,
- and available budget.

## Requirements

- MATLAB R2021b or later
- Optimization Toolbox (`intlinprog`)
- Mapping Toolbox is recommended for map output
- Internet access is recommended for road-distance downloads and basemaps

## Run the project

Open MATLAB in the repository root and run:

```matlab
main
```

The script:

1. Reads every city CSV in `data/`.
2. Loads city-specific settings from `settings.csv`.
3. Assigns charger types and installation costs.
4. Loads or downloads road-network distances.
5. Solves the station-location optimization.
6. Saves reports, CSV files, plots, and maps in `results/<city>/`.

## Project structure

```text
main.m             Runs all city datasets
settings.csv       City-specific model settings
data/              Candidate city datasets
src/               MATLAB functions
results/           Generated output files
```

## Candidate data format

Each city CSV in `data/` must contain:

```text
Name,Lat,Lon,Type,Weight_Car,Weight_Bike,PopDensity,LandCost
```

| Column | Description |
|---|---|
| `Name` | Site name |
| `Lat`, `Lon` | Coordinates in decimal degrees |
| `Type` | Site category |
| `Weight_Car` | Estimated car-demand score |
| `Weight_Bike` | Estimated electric-motorcycle demand score |
| `PopDensity` | Population-density score |
| `LandCost` | Relative land/site cost |

All numeric values must be finite. Demand and population scores should use
the same scale for every city.

### Dhaka candidate expansion

The Dhaka dataset includes 22 additional candidate reference locations,
increasing the candidate set from 30 to 52. Coordinates were
researched from OpenStreetMap/Nominatim and Overpass references. The added
`Weight_Car`, `Weight_Bike`, `PopDensity`, and `LandCost` values are
transparent planning estimates on the same 1-10 scale as the original
prototype data; they are not measured traffic, registration, census, or
property-price observations.

Source evidence for the added locations includes:

- [Dhaka candidate location research](https://nominatim.openstreetmap.org/)
- [OpenStreetMap Overpass API](https://overpass-api.de/)

Several candidates form spatial clusters and should not automatically be
treated as independent construction projects. Examples include Uttara,
Mirpur metro stations, Agargaon, Gulshan, Badda, New Market/Dhanmondi, and
the airport/railway area. Validate land availability, grid capacity, parking,
access, and actual demand before treating the estimates as investment data.

## City settings

`settings.csv` controls each city:

```csv
CityFile,R,p,budget,w_car,w_bike,w_pop,w_cost
dhaka,5,6,500,0.25,0.20,0.40,0.25
```

| Column | Description |
|---|---|
| `CityFile` | CSV filename without `.csv` |
| `R` | Service radius in kilometres |
| `p` | Maximum number of stations |
| `budget` | Total capital-cost limit |
| `w_car` | Car-demand weight |
| `w_bike` | Motorcycle-demand weight |
| `w_pop` | Population-density weight |
| `w_cost` | Land-cost penalty weight |

If a city is not listed, `main.m` uses its default parameters.

## Charger types and costs

The current rules assign:

| Site type | Charger |
|---|---|
| `TransportHub` | DC Fast |
| `Intersection` | DC Fast |
| `Highway` | DC Fast |
| `BusTerminal` | DC Fast |
| Other types | Level 2 |

These rules are a prototype and should be calibrated using traffic, parking,
vehicle, grid-capacity, and dwell-time data.

Charger cost is calculated using explicit components:

```text
AdjustedCost =
    LandCost
  + HardwareCost
  + GridUpgradeCost
  + CivilWorkCost
```

The profiles are defined in `main.m`:

```matlab
% [hardware, grid upgrade, civil/site work]
costProfile.level2 = [4, 1, 1];
costProfile.dcFast = [12, 8, 4];
```

The optimizer now chooses the charger type together with the site. Level 2 is
allowed at every candidate, while DC Fast is allowed at high-turnover sites
and candidates whose `Weight_Car` is at least 8. A minimum number of DC Fast
sites can be configured with `defaultParams.minFast` in `main.m`, or with a
`min_fast` column in `settings.csv`. The default minimum is 2.

The final station plan therefore reports a mixture of Level 2 and DC Fast
sites rather than assigning one fixed charger type before optimization.

These are relative model units, not Bangladeshi taka. Replace them with local
cost estimates if using real currency.

## Road-network distances

### Using a local Bangladesh road shapefile

Place the MATLAB-readable road shapefile at:

```text
geodata/maps/bangladesh_roads.shp
```

Keep its companion `.dbf`, `.shx`, and `.prj` files in the same folder. When
the shapefile exists, `main.m` reads the local road polylines, builds a local
undirected graph, computes shortest-path driving distances, and plots the road
network without online map or routing requests. This requires MATLAB Mapping
Toolbox.

See [geodata/maps/README.txt](geodata/maps/README.txt) for the expected local files.

For a city named `<city>`, the program uses:

```text
cache/road_distances/<city>_road_distances.csv
```

Each locally computed distance matrix also has a metadata sidecar:

```text
cache/road_distances/<city>_road_distances.csv.meta.mat
```

The sidecar stores candidate names and coordinates. The cache is checked before
the shapefile is opened and is reused only when those values still match the
current city CSV, preventing an old matrix from being applied to reordered or
changed candidate data.

For Dhaka:

```text
cache/road_distances/dhaka_road_distances.csv
```

The file must be an `n × n` distance matrix in kilometres, with rows and
columns in the same order as the city CSV.

`src/distMatrix.m` works as follows:

1. Requires the local road shapefile.
2. Builds a road graph from each shapefile polyline.
3. Connects each candidate site to the nearest point on a road segment.
4. Computes shortest-path distances locally.
5. Saves and validates the resulting city distance matrix.

No online road search or straight-line fallback is used. If the local road
shapefile is missing or disconnected, the program stops with a clear error.
Candidate-to-road connections use segment-level projection rather than
nearest-vertex snapping, which reduces access-distance error on long or
sparsely sampled road segments. Multipart shapefile geometry is also kept
separate at `NaN` separators so unrelated road parts are never joined.

The clipped road overlay used in each city's PNG map is cached under
`cache/map_overlays/<city>_local_roads_overlay.mat` so later runs do not
reread the full shapefile. Processed road graphs are stored in
`cache/road_graphs/`. Optimization maps use the local road overlay rather
than online street tiles to avoid basemap lag. The distance engine uses
shortest paths through the clipped local road graph between the nearest road
nodes; it does not sum arbitrary road segments.

## Optimization method

The program calculates a demand score:

```text
h = w_car  * Weight_Car
  + w_bike * Weight_Bike
  + w_pop  * PopDensity
  - w_cost * normalized LandCost
```

Coverage decreases linearly with distance:

```text
W(i,j) = 1 - distance(i,j) / R,  distance <= R
W(i,j) = 0,                      distance > R
```

The optimizer maximizes covered demand while enforcing:

```text
number of stations <= p
total AdjustedCost <= budget
```

MATLAB's `intlinprog` selects the final candidate sites.

## Output files

For each city, files are saved in `results/<city>/`:

| File | Description |
|---|---|
| `selected_stations.csv` | Selected sites, charger types, and costs |
| `selected_stations.txt` | Human-readable summary |
| `coverage_map.png` | Candidate and selected locations |
| `sensitivity_combined.png` | Single colored plot comparing station count, budget, and service-radius sensitivity |

The root `results/all_cities_summary.csv` contains one row per processed city,
including candidate count, selected station count, demand coverage, budget
usage, and Level 2/DC Fast station counts. Sensitivity ranges are derived
from each city's candidate count, configured station limit, service radius,
and observed distance matrix rather than fixed global values.

The selected-stations CSV includes:

- `ChargerType`
- `HardwareCost`
- `GridUpgradeCost`
- `CivilWorkCost`
- `AdjustedCost`

## Important limitations

This is a research prototype. Results depend on the quality of the input
scores and cost assumptions. The current model does not yet include:

- measured charging demand,
- traffic congestion or travel time,
- grid capacity and reliability,
- flood risk,
- parking and queue capacity,
- land ownership,
- separate charger quantities,
- separate bus, taxi, fleet, and motorcycle charging models,
- or equity constraints between neighbourhoods.

Selected sites should be checked through field surveys before construction.

## Troubleshooting

### `No candidate CSV files found`

Add at least one city dataset to `data/`.

### `intlinprog` is unavailable

Install or activate MATLAB Optimization Toolbox.

### Road-distance download fails

The project no longer downloads road distances. Check that
`geodata/maps/bangladesh_roads.shp` and its companion files are present and that
MATLAB Mapping Toolbox is installed.

### The map fails

Install Mapping Toolbox or adapt `src/plotMap.m` to use a plain scatter plot.

### Fewer than `p` stations are selected

The budget may be too small. Increase `budget` or reduce `p`.
