# Pune Transit Monitor: Project Guide

## What this project is

This is a local Data Analytics portfolio project about Pune PMPML bus schedules.
It turns a public GTFS ZIP file into clean CSV files that can be explored with
Python, queried with optional SQLite SQL, and visualized in Power BI.

## The simple flow

```text
GTFS ZIP → data/raw → Python cleaning → data/cleaned → SQL / EDA / Power BI → insights
```

1. `scripts/download_data.py` downloads a pinned public GTFS ZIP into `data/raw`.
   If downloading fails, manually place a valid GTFS ZIP there instead.
2. `scripts/clean_data.py` reads the ZIP, removes invalid or duplicate records,
   checks key relationships, converts dates and GTFS times, and writes clean CSVs.
3. `sql/schema.sql` is optional: use it in SQLite when demonstrating SQL.
4. `eda/eda.ipynb` explores the clean data and produces charts.
5. `powerbi/README.md` explains how to create the dashboard from the same CSVs.

## Why cleaning is needed

GTFS is a group of related text files. A trip should refer to a real route, a
stop-time should refer to a real trip and stop, coordinates should be numeric,
and schedule times can exceed 24:00 after midnight. The cleaning script handles
these details before analysis.

## Output datasets

| File | Why it exists |
| --- | --- |
| `routes_clean.csv` | Route labels and types |
| `stops_clean.csv` | Stop names and locations |
| `trips_clean.csv` | Route/service/direction trip records |
| `stop_times_clean.csv` | Clean timetable events and service-day seconds |
| `calendar_clean.csv` | Weekly service patterns, when present |
| `calendar_dates_clean.csv` | Service exceptions, when present |
| `transit_schedule_analysis_clean.csv` | Flat analysis table for EDA and Power BI |

## Insights to investigate

- Which routes have the most scheduled trips?
- Which stops are served by the most distinct routes?
- Where are scheduled headways long or inconsistent?
- How do morning, midday, evening, and night schedules differ?

These are scheduled-service insights. They do not measure actual bus arrivals,
passenger demand, ridership, or reliability because those datasets are absent.
