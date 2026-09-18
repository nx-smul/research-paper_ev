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
ID,Name,Lat,Lon,Type,Weight_Car,Weight_Bike,PopDensity,LandCost
```

| Column | Description |
|---|---|
| `ID` | Unique site identifier |
| `Name` | Site name |
| `Lat`, `Lon` | Coordinates in decimal degrees |
| `Type` | Site category |
| `Weight_Car` | Estimated car-demand score |
| `Weight_Bike` | Estimated electric-motorcycle demand score |
| `PopDensity` | Population-density score |
| `LandCost` | Relative land/site cost |

All numeric values must be finite. Demand and population scores should use
the same scale for every city.

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

These are relative model units, not Bangladeshi taka. Replace them with local
cost estimates if using real currency.

## Road-network distances

For a city named `<city>`, the program uses:

```text
data/<city>_road_distances.csv
```

For Dhaka:

```text
data/dhaka_road_distances.csv
```

The file must be an `n × n` distance matrix in kilometres, with rows and
columns in the same order as the city CSV.

`src/distMatrix.m` works as follows:

1. Loads and validates the cached matrix if it exists.
2. Otherwise requests driving distances from OSRM.
3. Saves the downloaded matrix for future runs.
4. Uses straight-line Haversine distance if the download fails.

The fallback allows the project to run without internet access, but cached
road distances are preferred for more realistic results.

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
| `sensitivity_p.png` | Coverage versus station count |
| `sensitivity_budget.png` | Coverage versus budget |
| `sensitivity_R.png` | Coverage versus service radius |

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

Check internet access. The program will use straight-line distance instead.

### The map fails

Install Mapping Toolbox or adapt `src/plotMap.m` to use a plain scatter plot.

### Fewer than `p` stations are selected

The budget may be too small. Increase `budget` or reduce `p`.
