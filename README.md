**# Pune Transit Schedule Analytics**

A data analytics project that transforms public PMPML GTFS schedule data into clean, validated, analysis-ready datasets and uses Python, SQL, and Power BI to understand Pune's scheduled transit network.

The project focuses on **\*\*planned transit schedules\*\***, including route activity, stop coverage, scheduled service patterns, geographic distribution, and planned headways.

\> **\*\*Important:\*\*** This project analyzes scheduled GTFS data only. It does not measure real-time bus locations, actual delays, ridership, passenger demand, or service reliability.

\---

**## Project Overview**

Pune's public transit schedule data is published in GTFS (General Transit Feed Specification) format. Although GTFS provides a standardized structure, the raw files contain multiple related tables and are not immediately convenient for analytical use.

This project builds a reproducible local analytics workflow that:

\- Downloads a pinned public PMPML GTFS feed.

\- Validates the source and required GTFS files.

\- Cleans and transforms the raw data using Python.

\- Handles GTFS-specific overnight schedule times.

\- Validates relationships and geographic coordinates.

\- Generates analysis-ready CSV datasets.

\- Loads the data into SQLite for SQL analysis.

\- Performs exploratory data analysis using Python.

\- Builds an interactive Power BI dashboard.

\- Uses automated tests to validate critical pipeline logic.

The overall workflow is:

\`\`\`text

Public PMPML GTFS ZIP

          ↓

Python Data Ingestion

          ↓

Validation & Cleaning

          ↓

Analysis-Ready CSV Files

          ↓

SQLite Database

          ↓

SQL Analysis + Python EDA

          ↓

Power BI Dashboard

\`\`\`

**## Problem Statement**

PMPML transit schedule information is available as raw GTFS files containing routes, stops, trips, stop times, and service calendars.

Although the data follows a standardized format, it is difficult to analyze directly.

The project addresses questions such as:

\- Which routes have the most scheduled trips?

\- Which routes have the most scheduled stop visits?

\- Which stops are served by the largest number of routes?

\- Which stops have the highest scheduled activity?

\- Where are transit stops geographically distributed?

\- What are the planned gaps between consecutive scheduled arrivals?

\- How is scheduled service distributed throughout the day?

\- How much scheduled service continues after midnight?

The goal is to transform the raw GTFS feed into reliable analytical datasets and use them to understand the structure and scheduled activity of Pune's transit network.

**## Project Objectives**

The project aims to:

\- Build a reproducible GTFS data ingestion workflow.

\- Validate the structure and integrity of the source data.

\- Remove duplicate and orphan records.

\- Validate transit stop coordinates.

\- Correctly handle GTFS times beyond 24:00:00.

\- Calculate planned schedule headways.

\- Generate clean, analysis-ready datasets.

\- Perform SQL-based transit schedule analysis.

\- Perform exploratory data analysis using Python.

\- Build a professional Power BI reporting layer.

\- Validate critical transformation logic using automated tests.

\- Document the complete analytical workflow.

**## Data Source**

The project uses a public PMPML GTFS schedule feed covering Pune, Maharashtra.

GTFS is a standardized format used to represent public transportation schedules and related information.

The processed feed contains:

\| Metric | Records |

\| :--- | :--- |

\| **\*\*Routes\*\*** | 627 |

\| **\*\*Stops\*\*** | 6,696 |

\| **\*\*Trips\*\*** | 15,138 |

\| **\*\*Scheduled Stop Visits\*\*** | 627,199 |

The dataset contains approximately:

\- 41.43 scheduled stop visits per trip.

These figures describe the processed schedule feed and should not be interpreted as real-world passenger or operational performance.

**## Project Architecture**

\`\`\`text

                         PMPML GTFS

                             │

                             ▼

                  ┌─────────────────────┐

                  │ download_data.py    │

                  │                     │

                  │ • Download feed     │

                  │ • Verify checksum   │

                  │ • Validate ZIP      │

                  │ • Check GTFS files  │

                  └──────────┬──────────┘

                             │

                             ▼

                  ┌─────────────────────┐

                  │ clean_data.py       │

                  │                     │

                  │ • Validate tables   │

                  │ • Remove duplicates │

                  │ • Remove orphans    │

                  │ • Validate coords   │

                  │ • Handle GTFS time  │

                  │ • Calculate headway │

                  └──────────┬──────────┘

                             │

                             ▼

                     Clean CSV Files

                             │

                ┌────────────┴────────────┐

                ▼                         ▼

          SQLite Database             EDA Notebook

                │                         │

                ▼                         ▼

          SQL Analysis                 Findings

                │                         │

                └────────────┬────────────┘

                             ▼

                       Power BI

                        Dashboard

\`\`\`

**## Data Pipeline**

**### 1. Data Ingestion**

**\*\*File:\*\*** \`scripts/download_data.py\`

The ingestion script downloads the pinned public GTFS ZIP and verifies the source before processing.

The script checks:

\- The downloaded file is a valid ZIP archive.

\- Required GTFS files are present.

\- The file checksum matches the expected version.

Required files include:

\- \`routes.txt\`

\- \`stops.txt\`

\- \`trips.txt\`

\- \`stop_times.txt\`

\- \`calendar.txt\`

This provides a reproducible starting point for the analytical pipeline.

**### 2. Data Cleaning and Transformation**

**\*\*File:\*\*** \`scripts/clean_data.py\`

The cleaning pipeline performs the following operations:

\- Removes duplicate route identifiers.

\- Removes duplicate stop identifiers.

\- Removes duplicate trip identifiers.

\- Removes orphan trips referencing missing routes.

\- Removes stop-time records referencing missing trips or stops.

\- Converts latitude and longitude values to numeric values.

\- Validates Pune-area geographic coordinates.

\- Handles missing text fields.

\- Converts GTFS dates into usable date formats.

\- Converts GTFS schedule times into seconds after service-day midnight.

\- Preserves overnight GTFS times.

\- Adds service-day offset information.

\- Calculates planned headways between consecutive scheduled arrivals.

**### GTFS Overnight Time Handling**

One of the important technical challenges in the project is handling GTFS schedule times beyond 24:00:00.

GTFS allows values such as:

\- \`24:10:00\`

\- \`25:10:00\`

\- \`27:05:16\`

These are valid schedule times.

For example, \`27:05:16\` represents \`03:05:16\` on the following calendar day while still belonging to the original GTFS service day.

The project preserves this information instead of treating the value as an invalid clock time.

This is important for correctly calculating overnight arrivals and scheduled headways.

**## Cleaned Datasets**

The pipeline generates the following analysis-ready files under \`data/cleaned/\`:

\- \`routes_clean.csv\`

\- \`stops_clean.csv\`

\- \`trips_clean.csv\`

\- \`stop_times_clean.csv\`

\- \`calendar_clean.csv\`

\- \`transit_schedule_analysis_clean.csv\`

**### Dataset descriptions**

\| Dataset | Purpose |

\| :--- | :--- |

\| \`routes_clean.csv\` | Clean route information |

\| \`stops_clean.csv\` | Stop names and geographic coordinates |

\| \`trips_clean.csv\` | Valid trips connected to valid routes |

\| \`stop_times_clean.csv\` | Scheduled arrivals and departures |

\| \`calendar_clean.csv\` | Service days and feed validity |

\| \`transit_schedule_analysis_clean.csv\` | Combined analytical schedule dataset |

**## SQLite Database**

The cleaned datasets are structured for relational analysis using SQLite.

Main tables include:

\- \`routes\`

\- \`stops\`

\- \`calendar\`

\- \`trips\`

\- \`stop_times\`

\- \`calendar_dates\`

The database supports analytical queries covering:

\- Route activity

\- Scheduled trips

\- Scheduled stop visits

\- Stop route coverage

\- Planned headways

\- Schedule timing

The database is generated locally from the cleaned datasets.

**## SQL Analysis**

SQL analysis is maintained in \`sql/\`.

The analysis covers questions such as:

\- **\*\*Network metrics:\*\*** Total routes, total stops, total trips, total scheduled stop visits.

\- **\*\*Route analysis:\*\*** Trips per route, scheduled stop visits per route, route activity rankings.

\- **\*\*Stop analysis:\*\*** Number of routes serving each stop, scheduled visits per stop, stop coverage rankings.

\- **\*\*Schedule analysis:\*\*** Planned headways, average/median scheduled gaps, route-level schedule characteristics.

Window functions such as \`LAG()\` can be used to compare consecutive scheduled arrivals and calculate planned headways.

**## Exploratory Data Analysis**

The EDA notebook is located at \`eda/eda.ipynb\`.

The notebook uses Python, Pandas, Matplotlib, Seaborn, and Jupyter Notebook.

The analysis includes:

\- **\*\*Dataset Overview:\*\*** Dataset dimensions, record counts, data quality checks, missing values.

\- **\*\*Route Activity:\*\*** Scheduled trips by route, scheduled stop visits by route, high-activity routes.

\- **\*\*Stop Activity:\*\*** Stops with highest route coverage, stops with highest scheduled visits.

\- **\*\*Schedule Analysis:\*\*** Arrival-time distribution, planned headway statistics, time-of-day activity, overnight service.

\- **\*\*Geographic Analysis:\*\*** Transit stop coordinates, geographic distribution of stops.

**## Key Findings**

**### Network Size**

The processed PMPML schedule feed contains:

\- 627 routes

\- 6,696 stops

\- 15,138 scheduled trips

\- 627,199 scheduled stop visits

The average number of scheduled stop visits per trip is approximately **\*\*41.43\*\***.

**### Highest Scheduled Route Activity**

The route numbers with the highest scheduled stop activity include:

\- **\*\*Route 149:\*\*** 13,753 scheduled stop visits

\- **\*\*Route 159:\*\*** 10,170 scheduled stop visits

\- **\*\*Route 43:\*\*** 9,527 scheduled stop visits

Route numbers can appear under multiple GTFS route_id values. Therefore, route-level analysis should preserve the underlying GTFS route definitions rather than assuming that every route number represents one unique record.

**### Highest Route Coverage Stops**

Stops with the highest number of route records serving them include:

\- **\*\*Swargate:\*\*** 96 routes serving stop, 2,519 scheduled visits

\- **\*\*Pune Station Moledina Stand:\*\*** 79 routes serving stop, 2,101 scheduled visits

\- **\*\*St Colony:\*\*** 79 routes serving stop, 1,893 scheduled visits

\- **\*\*Bhapkar Petrol Pump:\*\*** 76 routes serving stop, 1,785 scheduled visits

\- **\*\*Income Tax Office:\*\*** 69 routes serving stop, 1,814 scheduled visits

Swargate has the highest number of distinct route records serving the stop in the processed dataset.

This indicates high network connectivity in the schedule data, although route connectivity alone does not establish passenger demand or actual interchange behavior.

**### Planned Headways**

The planned headway analysis shows:

\- **\*\*25th Percentile:\*\*** 15 minutes

\- **\*\*Median:\*\*** 20 minutes

\- **\*\*75th Percentile:\*\*** 35 minutes

\- **\*\*90th Percentile:\*\*** 85 minutes

These values represent planned schedule gaps between consecutive scheduled arrivals.

They do not represent:

\- Actual waiting time

\- Actual bus frequency

\- Actual delays

\- Service reliability

**### Scheduled Service by Time of Day**

Scheduled stop visits are distributed as follows:

\- **\*\*Midday:\*\*** 273,678 scheduled stop visits

\- **\*\*Evening Peak:\*\*** 128,009 scheduled stop visits

\- **\*\*Morning Peak:\*\*** 105,732 scheduled stop visits

\- **\*\*Night:\*\*** 102,711 scheduled stop visits

\- **\*\*Early/Late:\*\*** 17,069 scheduled stop visits

Midday represents approximately 43.6% of scheduled stop visits in the processed feed.

**### Overnight Service**

The feed contains:

\- 4,671 scheduled arrivals after midnight

\- Latest scheduled arrival: \`27:05:16\`

The pipeline preserves these extended GTFS times correctly so that overnight schedules remain associated with the original service day.

\---

**## Power BI Dashboard

The project includes a streamlined three-page Power BI dashboard designed with a minimalist, professional analytics theme.

```text
Network Overview
       ↓
Route & Service Analysis
       ↓
Stops & Schedule Analysis
```

The design uses:

- **Light background**
- **Dark navy typography**
- **Blue primary accent**
- **White cards**
- **Minimal borders**
- **Consistent icons**
- **Clear KPI hierarchy**
- **Simple charts**
- **Geographic visualization**
- **Consistent navigation**

The objective is to create a clean analytical interface rather than an overly decorative dashboard.

---

### Page 1 — Network Overview

**Purpose:** The Network Overview page provides a high-level view of the Pune scheduled transit network. It answers what the overall scheduled PMPML network looks like.

- **Filters:** Route, Direction
- **KPI Cards:** Total Routes, Total Stops, Total Trips, Scheduled Stop Visits, Scheduled Visits per Trip, Overnight Scheduled Visits
- **Visualizations:**

  - **Top 10 Routes by Scheduled Trips:** Horizontal bar chart showing routes with the highest number of scheduled trips.

  - **Top 10 Routes by Scheduled Stop Visits:** Horizontal bar chart showing routes with the highest scheduled stop-visit volume.

  - **Pune Bus Stop Network:** Geographic map showing the distribution of transit stops across Pune.

  - **Scheduled Activity by Time of Day:** Column chart showing scheduled stop visits across Early/Late, Morning Peak, Midday, Evening Peak, and Night.

  - **Schedule Characteristics:** Compact analytical table showing Overnight Visit %, Maximum Headway, Minimum Headway, Median Headway, and Average Headway.

  - **Insight Panel:** Short contextual summary communicating the overall structure of the scheduled network.

- **Current status:** Complete.

---

### Page 2 — Route & Service Analysis

**Purpose:** The Route & Service Analysis page focuses on scheduled route activity and directional patterns, answering how scheduled service is distributed across routes and directions.

- **Filters:** Route, Direction
- **KPI Cards:** Total Trips, Trips per Route, Scheduled Stop Visits, Scheduled Visits per Trip, Routes with Scheduled Service
- **Visualizations:**

  - **Top 10 Routes by Scheduled Trips:** Horizontal bar chart showing routes with the highest number of scheduled trips.

  - **Top 10 Routes by Scheduled Stop Visits:** Horizontal bar chart showing routes with the highest scheduled stop-visit volume.

  - **Scheduled Trips by Direction:** Donut chart showing the distribution of scheduled trips across direction IDs.

  - **Route Coverage vs Scheduled Trips:** Scatter plot comparing scheduled trips with scheduled stop visits across routes.

  - **Scheduled Activity by Route (Top 10):** Stacked bar chart showing scheduled stop activity across Early/Late, Morning Peak, Midday, Evening Peak, and Night for the top routes.

  - **Insight Panel:** Concise analytical interpretation of route-level scheduled service distribution.

- **Current status:** Complete.

---

### Page 3 — Stops & Schedule Analysis

**Purpose:** The Stops & Schedule Analysis page focuses on stop-level scheduled activity, network connectivity, service periods, and planned headways.

- **Filters:** Route, Direction, Stop Name, Service Period
- **KPI Cards:** Total Stops, Scheduled Stop Visits, Scheduled Visits per Stop, Average Headway, Median Headway, Overnight Scheduled Visits
- **Visualizations:**

  - **Pune Bus Stop Network:** Geographic map displaying the spatial distribution of scheduled transit stops.

  - **Top 10 Stops by Scheduled Stop Visits:** Horizontal bar chart showing stops with the highest scheduled stop-visit activity.

  - **Scheduled Activity by Time of Day:** Column chart showing scheduled stop visits across Early/Late, Morning Peak, Midday, Evening Peak, and Night.

  - **Headway Distribution:** Column chart grouping planned headway records into practical intervals from Under 5 minutes through 120+ minutes.

  - **Top 10 Stops by Routes Served:** Horizontal bar chart showing stops served by the largest number of distinct route records.

  - **Stop & Schedule Insights:** Concise text panel summarizing key stop-level and schedule-level findings.

- **Current status:** Complete.

---

### Dashboard analytical flow

The three pages intentionally move from broad network structure to increasingly detailed schedule analysis:

```text
Network
   ↓
Routes & Service
   ↓
Stops & Schedule
```

This keeps the report focused on the project's core questions without introducing unsupported measures such as ridership, passenger demand, real-time operations, delays, or reliability.

---

## Dashboard Design Principles**

**### Color Theme**

\- **\*\*Primary:\*\*** Navy / Dark Blue (\`#12243A\`)

\- **\*\*Accent:\*\*** Bright Blue

\- **\*\*Supporting:\*\*** Light Blue, White, Light Gray (\`#F7F9FC\`)

**### Layout**

Each page uses:

\- Consistent left navigation

\- Clear page title and short subtitle

\- Compact filters

\- KPI cards near the top

\- Analytical visuals in the main body

\- Insight/context panel

\- Consistent spacing and alignment

**### Navigation**

The left navigation contains:

\- Network Overview

\- Route Analysis

\- Stop Analysis

The active page is highlighted using the primary blue accent. Each analytical page includes a reset-filter interaction to return the page to its default state.

\---

**## Testing**

Automated tests are located in \`tests/test_pipeline.py\`.

The tests cover:

\- GTFS overnight-time conversion

\- Invalid time handling

\- Duplicate removal

\- Orphan record removal

\- Headway calculation

\- CSV output generation

\- GTFS ZIP validation

**\*\*Current test result:\*\*** \`5 passed\`

\---

**## Project Structure**

\`\`\`text

pune-transit-monitor/

│

├── .gitignore

├── README.md

├── pyproject.toml

├── requirements.txt

│

├── data/

│   │

│   ├── cleaned/

│   │   ├── calendar_clean.csv

│   │   ├── routes_clean.csv

│   │   ├── stops_clean.csv

│   │   ├── stop_times_clean.csv

│   │   ├── transit_schedule_analysis_clean.csv

│   │   └── trips_clean.csv

│   │

│   └── SQL analysis/

│       ├── Detailed scheduled gaps using LAG.csv

│       ├── Headway distribution by practical interval.csv

│       ├── Headway statistics by route direction and stop.csv

│       ├── Main project KPIs.csv

│       ├── Overall headway summary.csv

│       ├── Scheduled headway in minutes by route, direction, and stop.csv

│       ├── Separate KPI view for easier inspection.csv

│       ├── Stop coverage distribution.csv

│       ├── Stops and scheduled visits per route.csv

│       ├── Stops served by the most distinct routes.csv

│       ├── Stops with the most scheduled visits.csv

│       ├── Stops with their scheduled activity for mapping.csv

│       ├── Top routes by scheduled stop visits.csv

│       ├── Top routes by scheduled trips.csv

│       └── Trips per route.csv

│

├── docs/

│   └── project_guide.md

│

├── eda/

│   └── eda.ipynb

│

├── powerbi/

│   ├── Pune_Transit_Schedule_Analytics.pbix

│   └── README.md

│

├── scripts/

│   ├── \_\_init\_\_.py

│   ├── build_sqlite.py

│   ├── clean_data.py

│   ├── download_data.py

│   └── load_sqlite.py

│

├── sql/

│   ├── schema.sql

│   └── schema_strengthened.sql

│

└── tests/

    └── test_pipeline.py

\`\`\`

\---

**## How to Run the Project**

1\. **\*\*Clone the repository:\*\***

   \`\`\`bash

   git clone https\://github.com/adityabharti83/pune-transit-monitor.git

   cd pune-transit-monitor

   \`\`\`

2\. **\*\*Create a virtual environment:\*\***

   \`\`\`bash

   python -m venv venv

   # Windows:

   venv\Scripts\activate

   \`\`\`

3\. **\*\*Install dependencies:\*\***

   \`\`\`bash

   pip install -r requirements.txt

   \`\`\`

4\. **\*\*Download the GTFS feed:\*\***

   \`\`\`bash

   python scripts/download_data.py

   \`\`\`

5\. **\*\*Run the cleaning pipeline:\*\***

   \`\`\`bash

   python scripts/clean_data.py

   \`\`\`

6\. **\*\*Run tests:\*\***

   \`\`\`bash

   pytest

   \`\`\`

   *\*Expected result: 5 passed\**

7\. **\*\*Explore the EDA:\*\*** Open \`eda/eda.ipynb\`.

8\. **\*\*Perform SQL analysis:\*\*** Use the SQLite database and SQL queries provided in \`sql/\`.

9\. **\*\*Build or open the Power BI report:\*\*** Use the cleaned datasets and the Power BI implementation guide under \`powerbi/README.md\`.

\---

**## Project Limitations**

This project is based on static GTFS schedule data. It does not measure:

\- Real-time bus locations

\- Actual arrival times

\- Actual delays

\- Cancellations

\- Ridership

\- Passenger demand

\- Passenger waiting time

\- Vehicle occupancy

\- Service reliability

\- Traffic conditions

Therefore, all schedule-related metrics should be interpreted as planned/scheduled values. For example, a 20-minute scheduled headway means two consecutive scheduled arrivals are 20 minutes apart in the timetable. It does not mean that passengers actually experienced a 20-minute waiting time.

\---

**## Future Scope**

The project can be extended by combining static GTFS schedules with additional transportation datasets, such as:

\- GTFS-Realtime vehicle positions

\- Bus GPS data

\- Actual arrival/departure logs

\- Ridership and ticketing data

\- Passenger feedback, traffic, and weather data

Future analysis could then explore actual versus scheduled arrivals, on-time performance, delay patterns, route reliability, passenger demand, waiting times, crowding, service accessibility, and service changes over time.

\---

**## Skills Demonstrated**

\- **\*\*Data Engineering:\*\*** Python, Pandas, data ingestion, cleaning, validation, GTFS processing, transformation.

\- **\*\*Data Analytics:\*\*** SQL, SQLite, Exploratory Data Analysis, statistical summaries, visualization, schedule analysis.

\- **\*\*Business Intelligence:\*\*** Power BI, data modeling, DAX, KPI design, interactive filtering, dashboard design, geographic visualization.

\- **\*\*Software Engineering:\*\*** Pytest, automated testing, reproducible workflows, Git, GitHub, project documentation.

\---

**## Project Status

| Component | Status |
| :--- | :--- |
| Project architecture | Complete |
| GTFS ingestion | Complete |
| Data validation | Complete |
| Data cleaning | Complete |
| Clean CSV datasets | Complete |
| SQLite database | Complete |
| SQL analysis | Complete |
| EDA notebook | Complete |
| Automated tests | Complete |
| Power BI data preparation | Complete |
| Network Overview | Complete |
| Route & Service Analysis | Complete |
| Stops & Schedule Analysis | Complete |
| Final Power BI report | Complete |
| Final documentation | Complete |

---

## Final Objective**

The final project aims to demonstrate an end-to-end data analytics workflow:

\`\`\`text

Real Public Data

      ↓

Data Collection

      ↓

Data Validation

      ↓

Data Cleaning

      ↓

Data Transformation

      ↓

SQL Analysis

      ↓

Exploratory Analysis

      ↓

Business Insights

      ↓

Power BI Dashboard

\`\`\`

The project demonstrates how raw public transportation data can be transformed into a structured analytical product that makes scheduled transit activity easier to understand.

The final Power BI report presents this analysis through three connected views: **Network Overview**, **Route & Service Analysis**, and **Stops & Schedule Analysis**.

\---

**## Author**

**\*\*Aditya Bharti\*\***  

Data Analytics | Python | SQL | Power BI  

GitHub: [https\://github.com/adityabharti83]\(https\://github.com/adityabharti83)