# Power BI guide

## Import these cleaned CSV files

Import `routes_clean.csv`, `stops_clean.csv`, `trips_clean.csv`,
`stop_times_clean.csv`, and `transit_schedule_analysis_clean.csv` from
`data/cleaned`. Import calendar files only when they were produced.

## Recommended model

Use the normalized tables for relationships:

```text
routes_clean[route_id]  1 → * trips_clean[route_id]
trips_clean[trip_id]    1 → * stop_times_clean[trip_id]
stops_clean[stop_id]    1 → * stop_times_clean[stop_id]
calendar_clean[service_id] 1 → * trips_clean[service_id]
```

Use single-direction relationships. Use `transit_schedule_analysis_clean` for
visuals that need route, stop, schedule, and headway columns together.

## Useful DAX measures

```DAX
Total Routes = DISTINCTCOUNT(routes_clean[route_id])
Total Stops = DISTINCTCOUNT(stops_clean[stop_id])
Total Trips = DISTINCTCOUNT(trips_clean[trip_id])
Scheduled Stop Visits = COUNTROWS(stop_times_clean)
Average Headway (Minutes) = AVERAGE(transit_schedule_analysis_clean[headway_minutes])
Routes per Stop = DISTINCTCOUNT(transit_schedule_analysis_clean[route_id])
Stops per Route = DISTINCTCOUNT(transit_schedule_analysis_clean[stop_id])
```

## Dashboard pages

1. **Transit overview:** total routes, stops, trips, scheduled visits; trips by route.
2. **Route analysis:** trips and distinct stops by route, direction slicer.
3. **Stop analysis:** routes per stop, most served stops, coordinate scatter plot.
4. **Schedule analysis:** average headway by route/stop and service period.
5. **Insights:** short written findings supported by the visuals.

For every chart, state the question it answers. Example: “Which stops have the
most route choice?” Use a bar chart of `Routes per Stop`; high values indicate
network interchange opportunities, not passenger volume.
