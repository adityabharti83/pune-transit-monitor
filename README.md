# Pune Transit Schedule Analytics

![Python](https://img.shields.io/badge/Python-3.x-3776AB?logo=python&logoColor=white)
![SQLite](https://img.shields.io/badge/SQLite-SQL%20Analysis-003B57?logo=sqlite&logoColor=white)
![Power BI](https://img.shields.io/badge/Power%20BI-Dashboard-F2C811?logo=powerbi&logoColor=black)
![Tests](https://img.shields.io/badge/pytest-5%20passed-brightgreen?logo=pytest&logoColor=white)

An end-to-end data analytics project that turns the public **PMPML GTFS** schedule feed into clean, validated, analysis-ready datasets, then explores Pune's scheduled bus network using **Python, SQL, and Power BI**.

> **Scope note:** This project analyzes **planned (scheduled) GTFS data only**. It does not measure real-time bus locations, actual delays, ridership, passenger demand, or service reliability.

---

## Table of Contents

- [Overview](#overview)
- [Problem Statement](#problem-statement)
- [Data Source](#data-source)
- [Architecture](#architecture)
- [Data Pipeline](#data-pipeline)
- [Cleaned Datasets](#cleaned-datasets)
- [SQL Analysis](#sql-analysis)
- [Exploratory Data Analysis](#exploratory-data-analysis)
- [Key Findings](#key-findings)
- [Power BI Dashboard](#power-bi-dashboard)
- [Testing](#testing)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
- [Limitations](#limitations)
- [Future Scope](#future-scope)
- [Skills Demonstrated](#skills-demonstrated)
- [Author](#author)

---

## Overview

Pune's public transit schedule is published in the standardized **GTFS** (General Transit Feed Specification) format. GTFS is well structured, but it is split across several related tables and is not convenient to analyze directly.

This project builds a reproducible local workflow that:

- Downloads a pinned public PMPML GTFS feed and verifies its integrity
- Validates the source ZIP and required GTFS files
- Cleans and transforms the raw data with Python
- Correctly handles GTFS overnight times (beyond `24:00:00`)
- Validates table relationships and geographic coordinates
- Produces analysis-ready CSV datasets
- Loads the data into SQLite for SQL analysis
- Performs exploratory data analysis (EDA) in a Jupyter notebook
- Presents the results in an interactive three-page Power BI dashboard
- Protects critical pipeline logic with automated tests

---

## Problem Statement

PMPML schedule data is available as raw GTFS files covering routes, stops, trips, stop times, and service calendars. This project answers questions such as:

- Which routes have the most scheduled trips and scheduled stop visits?
- Which stops are served by the largest number of routes?
- Which stops have the highest scheduled activity?
- How are transit stops distributed geographically?
- What are the planned gaps (headways) between consecutive scheduled arrivals?
- How is scheduled service distributed across the day?
- How much scheduled service runs after midnight?

---

## Data Source

The project uses a public PMPML GTFS schedule feed for Pune, Maharashtra. The processed feed contains:

| Metric | Records |
| :--- | ---: |
| Routes | 627 |
| Stops | 6,696 |
| Trips | 15,138 |
| Scheduled stop visits | 627,199 |

That works out to roughly **41.43 scheduled stop visits per trip**. These figures describe the processed schedule feed only; they are not measures of real-world passenger or operational performance.

---

## Architecture

```text
Public PMPML GTFS ZIP
        │
        ▼
┌──────────────────────┐
│  download_data.py    │  • Download pinned feed
│                      │  • Verify checksum
│                      │  • Validate ZIP
│                      │  • Check required GTFS files
└──────────┬───────────┘
           ▼
┌──────────────────────┐
│  clean_data.py       │  • Validate tables
│                      │  • Remove duplicates and orphans
│                      │  • Validate coordinates
│                      │  • Handle GTFS overnight times
│                      │  • Calculate planned headways
└──────────┬───────────┘
           ▼
     Clean CSV files
           │
   ┌───────┴────────┐
   ▼                ▼
SQLite DB      EDA Notebook
   │                │
   ▼                ▼
SQL Analysis     Findings
   │                │
   └───────┬────────┘
           ▼
   Power BI Dashboard
```

---

## Data Pipeline

### 1. Ingestion — `scripts/download_data.py`

Downloads the pinned GTFS ZIP and verifies it before any processing:

- The file is a valid ZIP archive
- The required GTFS files are present: `routes.txt`, `stops.txt`, `trips.txt`, `stop_times.txt`, `calendar.txt`
- The checksum matches the expected version

### 2. Cleaning and Transformation — `scripts/clean_data.py`

- Removes duplicate route, stop, and trip identifiers
- Removes orphan trips that reference missing routes
- Removes stop-time records that reference missing trips or stops
- Converts latitude and longitude to numeric values and validates Pune-area coordinates
- Handles missing text fields
- Converts GTFS dates into usable date formats
- Converts GTFS times into seconds after service-day midnight
- Preserves overnight times and adds service-day offset information
- Calculates planned headways between consecutive scheduled arrivals

### Handling GTFS Overnight Times

GTFS allows times beyond `24:00:00` (for example `24:10:00`, `25:10:00`, or `27:05:16`) so that trips running past midnight stay attached to their original service day. For example, `27:05:16` means `03:05:16` on the following calendar day, while still belonging to the original service day.

The pipeline preserves this information instead of treating such values as invalid clock times, which keeps overnight arrivals and headways correct.

---

## Cleaned Datasets

The pipeline writes the following files to `data/cleaned/`:

| Dataset | Purpose |
| :--- | :--- |
| `routes_clean.csv` | Clean route information |
| `stops_clean.csv` | Stop names and geographic coordinates |
| `trips_clean.csv` | Valid trips linked to valid routes |
| `stop_times_clean.csv` | Scheduled arrivals and departures |
| `calendar_clean.csv` | Service days and feed validity |
| `transit_schedule_analysis_clean.csv` | Combined analytical schedule dataset |

---

## SQL Analysis

The cleaned data is loaded into a local **SQLite** database (generated from the cleaned CSVs) with the tables `routes`, `stops`, `calendar`, `trips`, `stop_times`, and `calendar_dates`. Schema definitions live in `sql/`, and exported query results are stored in `data/SQL analysis/`.

| Area | Questions covered |
| :--- | :--- |
| **Network metrics** | Total routes, stops, trips, and scheduled stop visits |
| **Route analysis** | Trips per route, stop visits per route, route activity rankings |
| **Stop analysis** | Routes serving each stop, scheduled visits per stop, coverage rankings |
| **Schedule analysis** | Planned headways, average and median gaps, route-level characteristics |

Window functions such as `LAG()` are used to compare consecutive scheduled arrivals and compute planned headways.

---

## Exploratory Data Analysis

The EDA lives in `eda/eda.ipynb` and uses Python, Pandas, Matplotlib, Seaborn, and Jupyter.

- **Dataset overview:** dimensions, record counts, data-quality checks, missing values
- **Route activity:** scheduled trips and stop visits by route, high-activity routes
- **Stop activity:** stops with the highest route coverage and scheduled visits
- **Schedule analysis:** arrival-time distribution, headway statistics, time-of-day activity, overnight service
- **Geographic analysis:** stop coordinates and spatial distribution

---

## Key Findings

### Network Size

| Metric | Value |
| :--- | ---: |
| Routes | 627 |
| Stops | 6,696 |
| Scheduled trips | 15,138 |
| Scheduled stop visits | 627,199 |
| Avg. stop visits per trip | ~41.43 |

### Highest Scheduled Route Activity

| Route | Scheduled stop visits |
| :--- | ---: |
| Route 149 | 13,753 |
| Route 159 | 10,170 |
| Route 43 | 9,527 |

> A single route number can appear under multiple GTFS `route_id` values, so route-level analysis preserves the underlying GTFS route definitions instead of assuming one record per route number.

### Stops Served by the Most Routes

| Stop | Routes serving stop | Scheduled visits |
| :--- | ---: | ---: |
| Swargate | 96 | 2,519 |
| Pune Station Moledina Stand | 79 | 2,101 |
| St Colony | 79 | 1,893 |
| Bhapkar Petrol Pump | 76 | 1,785 |
| Income Tax Office | 69 | 1,814 |

Swargate is served by the most distinct route records, which points to high connectivity in the schedule. Connectivity alone does not establish passenger demand or actual interchange behavior.

### Planned Headways

| Percentile | Planned headway |
| :--- | ---: |
| 25th | 15 min |
| Median | 20 min |
| 75th | 35 min |
| 90th | 85 min |

These are planned gaps between consecutive scheduled arrivals. They do **not** represent actual waiting time, real bus frequency, delays, or reliability.

### Scheduled Service by Time of Day

| Period | Scheduled stop visits |
| :--- | ---: |
| Midday | 273,678 |
| Evening Peak | 128,009 |
| Morning Peak | 105,732 |
| Night | 102,711 |
| Early/Late | 17,069 |

Midday accounts for about **43.6%** of all scheduled stop visits.

### Overnight Service

- **4,671** scheduled arrivals fall after midnight
- The latest scheduled arrival is at `27:05:16`

---

## Power BI Dashboard

The report is a three-page dashboard with a minimalist, professional look: light background, dark navy text, a blue accent, white cards, and consistent icons and navigation.

```text
Network Overview  →  Route & Service Analysis  →  Stops & Schedule Analysis
```

The file is at `powerbi/Pune_Transit_Schedule_Analytics.pbix`, with implementation notes in `powerbi/README.md`.

<!--
Add screenshots here once they are in the repo, for example:
![Network Overview](docs/images/network_overview.png)
![Route & Service Analysis](docs/images/route_analysis.png)
![Stops & Schedule Analysis](docs/images/stop_analysis.png)
-->

### Page 1: Network Overview

*What does the overall scheduled PMPML network look like?*

- **Filters:** Route, Direction
- **KPI cards:** Total Routes, Total Stops, Total Trips, Scheduled Stop Visits, Scheduled Visits per Trip, Overnight Scheduled Visits
- **Visuals:**
  - Top 10 Routes by Scheduled Trips (bar)
  - Top 10 Routes by Scheduled Stop Visits (bar)
  - Pune Bus Stop Network (map)
  - Scheduled Activity by Time of Day (column)
  - Schedule Characteristics table (overnight visit %, and maximum, minimum, median, and average headway)
  - Insight panel

### Page 2: Route & Service Analysis

*How is scheduled service distributed across routes and directions?*

- **Filters:** Route, Direction
- **KPI cards:** Total Trips, Trips per Route, Scheduled Stop Visits, Scheduled Visits per Trip, Routes with Scheduled Service
- **Visuals:**
  - Top 10 Routes by Scheduled Trips (bar)
  - Top 10 Routes by Scheduled Stop Visits (bar)
  - Scheduled Trips by Direction (donut)
  - Route Coverage vs Scheduled Trips (scatter of scheduled trips against scheduled stop visits per route)
  - Scheduled Activity by Route, Top 10 (stacked bar by time-of-day period)
  - Insight panel

### Page 3: Stops & Schedule Analysis

*Where is scheduled activity concentrated, and what do planned headways look like?*

- **Filters:** Route, Direction, Stop Name, Service Period
- **KPI cards:** Total Stops, Scheduled Stop Visits, Scheduled Visits per Stop, Average Headway, Median Headway, Overnight Scheduled Visits
- **Visuals:**
  - Pune Bus Stop Network (map)
  - Top 10 Stops by Scheduled Stop Visits (bar)
  - Scheduled Activity by Time of Day (column)
  - Headway Distribution (column, from under 5 minutes to 120+ minutes)
  - Top 10 Stops by Routes Served (bar)
  - Stop & Schedule Insights panel

### Design Principles

- **Colors:** navy `#12243A` (primary), bright blue (accent), light blue, white, and light gray `#F7F9FC`
- **Layout:** consistent left navigation, page title and subtitle, compact filters, KPI cards at the top, visuals in the main body, and an insight panel
- **Navigation:** Network Overview, Route Analysis, Stop Analysis, with the active page highlighted in blue and a reset-filter button on each analytical page
- **Focus:** no unsupported measures such as ridership, demand, real-time operations, delays, or reliability

---

## Testing

Automated tests live in `tests/test_pipeline.py` and cover:

- GTFS overnight-time conversion
- Invalid time handling
- Duplicate removal
- Orphan record removal
- Headway calculation
- CSV output generation
- GTFS ZIP validation

**Current result:** `5 passed`

---

## Project Structure

```text
pune-transit-monitor/
├── .gitignore
├── README.md
├── pyproject.toml
├── requirements.txt
│
├── data/
│   ├── cleaned/
│   │   ├── calendar_clean.csv
│   │   ├── routes_clean.csv
│   │   ├── stops_clean.csv
│   │   ├── stop_times_clean.csv
│   │   ├── transit_schedule_analysis_clean.csv
│   │   └── trips_clean.csv
│   └── SQL analysis/            # exported SQL query results (15 CSVs)
│
├── docs/
│   └── project_guide.md
│
├── eda/
│   └── eda.ipynb
│
├── powerbi/
│   ├── Pune_Transit_Schedule_Analytics.pbix
│   └── README.md
│
├── scripts/
│   ├── __init__.py
│   ├── build_sqlite.py
│   ├── clean_data.py
│   ├── download_data.py
│   └── load_sqlite.py
│
├── sql/
│   ├── schema.sql
│   └── schema_strengthened.sql
│
└── tests/
    └── test_pipeline.py
```

---

## Getting Started

### Prerequisites

- Python 3.9 or newer
- Jupyter (installed via `requirements.txt`) for the EDA notebook
- Power BI Desktop (Windows) to open the `.pbix` report

### Setup

```bash
# 1. Clone the repository
git clone https://github.com/adityabharti83/pune-transit-monitor.git
cd pune-transit-monitor

# 2. Create and activate a virtual environment
python -m venv venv
venv\Scripts\activate          # Windows
# source venv/bin/activate     # macOS / Linux

# 3. Install dependencies
pip install -r requirements.txt
```

### Run the pipeline

```bash
# 4. Download and verify the GTFS feed
python scripts/download_data.py

# 5. Clean and transform the data
python scripts/clean_data.py

# 6. Build the SQLite database
python scripts/build_sqlite.py
python scripts/load_sqlite.py

# 7. Run the tests (expected: 5 passed)
pytest
```

### Explore the results

- **EDA:** open `eda/eda.ipynb` in Jupyter
- **SQL:** run the queries against the SQLite database using the schemas in `sql/`
- **Dashboard:** open `powerbi/Pune_Transit_Schedule_Analytics.pbix` (see `powerbi/README.md` for details)

---

## Limitations

This project is based on **static GTFS schedule data**. It does not measure:

- Real-time bus locations
- Actual arrival times, delays, or cancellations
- Ridership or passenger demand
- Passenger waiting time or vehicle occupancy
- Service reliability or traffic conditions

All schedule-related metrics are **planned values**. For example, a 20-minute scheduled headway means two consecutive scheduled arrivals are 20 minutes apart in the timetable, not that passengers actually waited 20 minutes.

---

## Future Scope

The project can be extended by combining the static schedule with:

- GTFS-Realtime vehicle positions
- Bus GPS data
- Actual arrival and departure logs
- Ridership and ticketing data
- Passenger feedback, traffic, and weather data

This would enable analysis of scheduled versus actual arrivals, on-time performance, delay patterns, route reliability, passenger demand, crowding, and service changes over time.

---

## Skills Demonstrated

| Area | Skills |
| :--- | :--- |
| **Data Engineering** | Python, Pandas, data ingestion, cleaning, validation, GTFS processing, transformation |
| **Data Analytics** | SQL, SQLite, EDA, statistical summaries, visualization, schedule analysis |
| **Business Intelligence** | Power BI, data modeling, DAX, KPI design, interactive filtering, geographic visualization |
| **Software Engineering** | Pytest, automated testing, reproducible workflows, Git, GitHub, documentation |

---

## Author

**Aditya Bharti**
Data Analytics | Python | SQL | Power BI

GitHub: [@adityabharti83](https://github.com/adityabharti83)
