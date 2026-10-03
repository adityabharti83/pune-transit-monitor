# Power BI Guide

This README is specific to the **Power BI dashboard folder**. It documents the Power BI data model, measures, page structure, visual design, and analytical usage of the cleaned GTFS data.

> The main project README is maintained separately and contains the overall project description, pipeline, data preparation, SQL analysis, testing, and project results.

---

## 1. Import the cleaned CSV files

Import these files from `data/cleaned/`:

- `routes_clean.csv`
- `stops_clean.csv`
- `trips_clean.csv`
- `stop_times_clean.csv`
- `transit_schedule_analysis_clean.csv`

Import the calendar files when they are available:

- `calendar_clean.csv`
- `calendar_dates_clean.csv`

### Purpose of the tables

| Table | Purpose |
|---|---|
| `routes_clean` | Route definitions and route metadata |
| `stops_clean` | Stop names and geographic coordinates |
| `trips_clean` | Scheduled trips, routes, service IDs, and directions |
| `stop_times_clean` | Scheduled arrivals/departures and stop sequences |
| `calendar_clean` | Scheduled service calendar |
| `calendar_dates_clean` | Calendar exceptions, when available |
| `transit_schedule_analysis_clean` | Denormalized analytical table containing route, stop, schedule, service-period, and headway fields |

---

## 2. Recommended data model

Use the normalized tables for the main Power BI model.

```text
routes_clean[route_id]       1 → * trips_clean[route_id]

trips_clean[trip_id]         1 → * stop_times_clean[trip_id]

stops_clean[stop_id]         1 → * stop_times_clean[stop_id]

calendar_clean[service_id]   1 → * trips_clean[service_id]
```

### Relationship settings

- Cardinality: **One-to-many**
- Cross-filter direction: **Single**
- Use the normalized model for the main network relationships.
- Keep `transit_schedule_analysis_clean` separate/disconnected from the normalized model when using it for analytical visuals that require route, stop, service-period, and headway fields together.
- The disconnected analytical table can be used with explicit DAX filtering (`TREATAS`) where required.

### Model principle

```text
Normalized GTFS tables
        ↓
Relationships
        ↓
Core network KPIs

transit_schedule_analysis_clean
        ↓
Route / Stop / Service Period / Headway analysis
```

---

## 3. Supporting tables

### Service Period

The `Service Period` table is used to provide a controlled order for schedule-period analysis.

Recommended order:

```text
1  Early/Late
2  Morning peak
3  Midday
4  Evening peak
5  Night
```

Use the sorted `Service Period[Service Period]` field for service-period slicers and legends where appropriate.

### Headway Bands

The `Headway Bands` table is used for the headway-distribution visual.

Recommended bands:

```text
Under 5 min
5–10 min
10–15 min
15–20 min
20–30 min
30–45 min
45–60 min
60–90 min
90–120 min
120+ min
```

The bands should be sorted using their numeric `Sort Order` column.

### Schedule Characteristics

A disconnected `Schedule Characteristics` table can be used to display schedule metrics as a compact `Metric | Value` table.

---

## 4. Core DAX measures

The following measures are used or recommended for the dashboard.

### Network KPIs

```DAX
Total Routes =
DISTINCTCOUNT(routes_clean[route_id])
```

```DAX
Total Stops =
DISTINCTCOUNT(stops_clean[stop_id])
```

```DAX
Total Trips =
DISTINCTCOUNT(trips_clean[trip_id])
```

```DAX
Scheduled Stop Visits =
COUNTROWS(stop_times_clean)
```

```DAX
Scheduled Visits per Trip =
DIVIDE(
    [Scheduled Stop Visits],
    [Total Trips]
)
```

```DAX
Scheduled Visits per Stop =
DIVIDE(
    [Scheduled Stop Visits],
    [Total Stops]
)
```

```DAX
Trips per Route =
DIVIDE(
    [Total Trips],
    [Total Routes]
)
```

```DAX
Routes with Scheduled Service =
DISTINCTCOUNT(trips_clean[route_id])
```

### Headway KPIs

```DAX
Headway Records =
COUNT(transit_schedule_analysis_clean[headway_minutes])
```

```DAX
Average Headway =
AVERAGE(transit_schedule_analysis_clean[headway_minutes])
```

```DAX
Median Headway =
MEDIAN(transit_schedule_analysis_clean[headway_minutes])
```

```DAX
Minimum Headway =
MIN(transit_schedule_analysis_clean[headway_minutes])
```

```DAX
Maximum Headway =
MAX(transit_schedule_analysis_clean[headway_minutes])
```

### Overnight service

```DAX
Overnight Scheduled Visits =
CALCULATE(
    COUNTROWS(transit_schedule_analysis_clean),
    transit_schedule_analysis_clean[arrival_day_offset] > 0
)
```

```DAX
Overnight Visit % =
DIVIDE(
    [Overnight Scheduled Visits],
    [Scheduled Stop Visits]
)
```

---

## 5. Route-level analytical measure

Because `transit_schedule_analysis_clean` is kept separate from the normalized model, use an explicit route filter when a visual needs route-level scheduled activity from the analytical table.

```DAX
Scheduled Activity by Route =
VAR SelectedRoutes =
    VALUES(routes_clean[route_id])
RETURN
CALCULATE(
    COUNTROWS(transit_schedule_analysis_clean),
    TREATAS(
        SelectedRoutes,
        transit_schedule_analysis_clean[route_id]
    )
)
```

When the visual also uses `Service Period[Service Period]` as a legend or slicer:

```DAX
Scheduled Activity by Route =
VAR SelectedRoutes =
    VALUES(routes_clean[route_id])

VAR SelectedPeriods =
    VALUES('Service Period'[Service Period])

RETURN
CALCULATE(
    COUNTROWS(transit_schedule_analysis_clean),
    TREATAS(
        SelectedRoutes,
        transit_schedule_analysis_clean[route_id]
    ),
    TREATAS(
        SelectedPeriods,
        transit_schedule_analysis_clean[service_period]
    )
)
```

This allows a route's scheduled stop visits to be split correctly across:

- Early/Late
- Morning peak
- Midday
- Evening peak
- Night

---

## 6. Headway distribution

For the headway distribution chart, use the `Headway Bands` table as the X-axis and a measure that counts records in each band.

The chart should represent the distribution of **scheduled headway records**, not actual observed bus intervals.

Important interpretation:

> Headway in this project means the scheduled time gap between consecutive scheduled arrivals for the same route, direction, and stop. It is not an observed real-world waiting time or reliability metric.

---

# 7. Dashboard pages

The dashboard contains **three pages only**.

## Page 1 — Network Overview

### Purpose

Answer:

> **What does the overall scheduled PMPML network look like?**

### Main KPIs

- Total Routes
- Total Stops
- Total Trips
- Scheduled Stop Visits
- Scheduled Visits per Trip
- Overnight Scheduled Visits

### Main visuals

1. **Top 10 Routes by Scheduled Trips**
2. **Top 10 Routes by Scheduled Stop Visits**
3. **Pune Bus Stop Network**
4. **Scheduled Activity by Time of Day**
5. **Schedule Characteristics**
6. **Network insight panel**

### Analytical focus

This page provides the overall scale and structure of the scheduled network.

---

## Page 2 — Route & Service Analysis

### Purpose

Answer:

> **How is scheduled service distributed across routes and directions?**

### Filters

- Route
- Direction

### Main KPIs

- Total Trips
- Trips per Route
- Scheduled Stop Visits
- Scheduled Visits per Trip
- Routes with Scheduled Service

### Main visuals

1. **Top 10 Routes by Scheduled Trips**
2. **Top 10 Routes by Scheduled Stop Visits**
3. **Scheduled Trips by Direction**
4. **Route Coverage vs Scheduled Trips**
5. **Scheduled Activity by Route (Top 10)**
6. **Route Service Distribution** insight panel

### Analytical focus

This page examines route-level service distribution, directional balance, and the relationship between scheduled trips and scheduled stop activity.

---

## Page 3 — Stops & Schedule Analysis

### Purpose

Answer:

> **Where is scheduled service concentrated, and how does scheduled frequency behave?**

### Filters

- Route
- Direction
- Stop Name
- Service Period

### Main KPIs

- Total Stops
- Scheduled Stop Visits
- Scheduled Visits per Stop
- Average Headway
- Median Headway
- Overnight Scheduled Visits

### Main visuals

1. **Pune Bus Stop Network**
2. **Top 10 Stops by Scheduled Stop Visits**
3. **Scheduled Activity by Time of Day**
4. **Headway Distribution**
5. **Top 10 Stops by Routes Served**
6. **Stop & Schedule Insights** panel

### Analytical focus

This page examines stop-level activity, geographic coverage, service-period patterns, scheduled headway distribution, route coverage at stops, and overnight scheduling.

---

# 8. Visual question framework

Each visual should answer a specific analytical question.

| Visual | Question it answers |
|---|---|
| Top 10 Routes by Scheduled Trips | Which routes have the highest number of scheduled trips? |
| Top 10 Routes by Scheduled Stop Visits | Which routes have the highest scheduled stop-visit volume? |
| Scheduled Trips by Direction | How are scheduled trips distributed across direction IDs? |
| Route Coverage vs Scheduled Trips | How does scheduled trip volume relate to scheduled stop activity across routes? |
| Scheduled Activity by Route (Top 10) | How is scheduled route activity distributed across service periods? |
| Pune Bus Stop Network | Where are the scheduled stops geographically distributed? |
| Top 10 Stops by Scheduled Stop Visits | Which stops have the highest scheduled stop-visit activity? |
| Scheduled Activity by Time of Day | How is scheduled stop activity distributed across service periods? |
| Headway Distribution | How are scheduled headway intervals distributed? |
| Top 10 Stops by Routes Served | Which stops are served by the greatest number of distinct routes? |
| Schedule Characteristics | What are the key scheduled headway and overnight-service characteristics? |

---

# 9. Interpretation guidelines

Use precise GTFS terminology when describing dashboard findings.

### Use

- scheduled trips
- scheduled stop visits
- scheduled headway
- scheduled service
- routes served
- service period
- direction ID
- stop coverage

### Do not interpret these measures as

- passenger demand
- ridership
- actual waiting time
- actual bus frequency
- delay
- reliability
- on-time performance
- passenger volume
- route popularity

For example:

> **Correct:** Route 149 has a high scheduled stop-visit volume in the displayed route analysis.

> **Avoid:** Route 149 has the highest passenger demand.

The GTFS schedule data does not contain passenger ridership.

---

# 10. Dashboard design standards

Maintain the same visual language across all three pages.

### Navigation

Only three report pages should be exposed through the sidebar:

```text
Network Overview
Route Analysis
Stop & Schedule Analysis
```

### Filters

Use the same styling and placement for slicers across pages.

### KPI cards

Use:

- white background
- rounded corners
- subtle shadow
- light-blue icon container
- dark navy values
- concise labels

### Charts

Use:

- white visual containers
- consistent navy titles
- blue primary data elements
- clear axis titles where useful
- data labels when they improve readability
- descending order for Top 10 rankings

### Insight panels

Use short, data-supported statements. Do not introduce claims about ridership, demand, reliability, or real-time performance because those are outside the scope of this scheduled GTFS project.

---

# 11. Recommended presentation flow

When presenting the dashboard:

```text
1. Network Overview
       ↓
   Establish network scale and overall schedule structure

2. Route & Service Analysis
       ↓
   Examine route-level service distribution and direction

3. Stops & Schedule Analysis
       ↓
   Examine stop activity, service periods, and scheduled headways
```

This creates a simple analytical progression:

**Network → Routes → Stops & Schedule**

---

## 12. Scope

This Power BI report is intentionally limited to **scheduled GTFS data**.

It does not attempt to measure real-time operations, passenger demand, ridership, delays, reliability, or service performance against actual observations.

The dashboard should therefore be interpreted as an analysis of the **published scheduled transit structure and operating patterns** represented by the GTFS feed.
