-- Pune Transit Schedule Analytics
-- Complete SQLite schema, analytical queries, and data-quality checks.
--
-- Purpose:
--   1. Define the relational schema for cleaned GTFS data.
--   2. Provide reproducible analytical SQL for the project.
--   3. Provide SQL-based validation checks for the loaded database.
--
-- Scope:
--   Scheduled GTFS analysis only. This does not measure real-time arrivals,
--   actual delays, ridership, passenger demand, or service reliability.

PRAGMA foreign_keys = ON;

-- ============================================================
-- 1. SCHEMA
-- ============================================================

CREATE TABLE IF NOT EXISTS routes (
    route_id TEXT PRIMARY KEY,
    route_short_name TEXT,
    route_long_name TEXT,
    route_desc TEXT,
    route_type INTEGER,
    route_color TEXT
);

CREATE TABLE IF NOT EXISTS stops (
    stop_id TEXT PRIMARY KEY,
    stop_name TEXT,
    stop_lat REAL,
    stop_lon REAL,
    stop_desc TEXT,
    zone_id TEXT
);

CREATE TABLE IF NOT EXISTS calendar (
    service_id TEXT PRIMARY KEY,
    monday INTEGER,
    tuesday INTEGER,
    wednesday INTEGER,
    thursday INTEGER,
    friday INTEGER,
    saturday INTEGER,
    sunday INTEGER,
    start_date TEXT,
    end_date TEXT
);

CREATE TABLE IF NOT EXISTS trips (
    trip_id TEXT PRIMARY KEY,
    route_id TEXT NOT NULL,
    service_id TEXT NOT NULL,
    trip_headsign TEXT,
    direction_id INTEGER,
    FOREIGN KEY (route_id) REFERENCES routes(route_id),
    FOREIGN KEY (service_id) REFERENCES calendar(service_id)
);

CREATE TABLE IF NOT EXISTS stop_times (
    trip_id TEXT NOT NULL,
    stop_id TEXT NOT NULL,
    arrival_time TEXT NOT NULL,
    departure_time TEXT NOT NULL,
    stop_sequence INTEGER NOT NULL,
    arrival_seconds INTEGER NOT NULL,
    departure_seconds INTEGER NOT NULL,
    arrival_day_offset INTEGER NOT NULL,
    stop_headsign TEXT,
    pickup_type TEXT,
    drop_off_type TEXT,
    PRIMARY KEY (trip_id, stop_sequence),
    FOREIGN KEY (trip_id) REFERENCES trips(trip_id),
    FOREIGN KEY (stop_id) REFERENCES stops(stop_id)
);

CREATE TABLE IF NOT EXISTS calendar_dates (
    service_id TEXT NOT NULL,
    date TEXT NOT NULL,
    exception_type INTEGER NOT NULL,
    PRIMARY KEY (service_id, date),
    FOREIGN KEY (service_id) REFERENCES calendar(service_id)
);

-- ============================================================
-- 2. INDEXES
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_trips_route
    ON trips(route_id);

CREATE INDEX IF NOT EXISTS idx_trips_service
    ON trips(service_id);

CREATE INDEX IF NOT EXISTS idx_stop_times_stop
    ON stop_times(stop_id);

CREATE INDEX IF NOT EXISTS idx_stop_times_trip
    ON stop_times(trip_id);

CREATE INDEX IF NOT EXISTS idx_stop_times_arrival
    ON stop_times(arrival_seconds);

CREATE INDEX IF NOT EXISTS idx_calendar_dates_service
    ON calendar_dates(service_id);

-- ============================================================
-- 3. NETWORK SUMMARY
-- ============================================================

-- Main project KPIs.
SELECT
    (SELECT COUNT(*) FROM routes) AS total_routes,
    (SELECT COUNT(*) FROM stops) AS total_stops,
    (SELECT COUNT(*) FROM trips) AS total_trips,
    (SELECT COUNT(*) FROM stop_times) AS total_scheduled_stop_visits,
    ROUND(
        (SELECT COUNT(*) FROM stop_times) * 1.0
        / NULLIF((SELECT COUNT(*) FROM trips), 0),
        2
    ) AS scheduled_visits_per_trip;

-- Separate KPI view for easier inspection.
SELECT
    COUNT(DISTINCT route_id) AS routes_with_trips,
    COUNT(DISTINCT t.trip_id) AS trips_with_stop_times,
    COUNT(DISTINCT stop_id) AS stops_with_scheduled_visits,
    COUNT(*) AS scheduled_stop_visits
FROM stop_times st
JOIN trips t
    ON st.trip_id = t.trip_id;

-- ============================================================
-- 4. ROUTE ANALYSIS
-- ============================================================

-- 4.1 Trips per route.
SELECT
    r.route_id,
    r.route_short_name,
    r.route_long_name,
    COUNT(t.trip_id) AS scheduled_trips
FROM routes r
LEFT JOIN trips t
    ON r.route_id = t.route_id
GROUP BY
    r.route_id,
    r.route_short_name,
    r.route_long_name
ORDER BY scheduled_trips DESC, r.route_id;

-- 4.2 Top routes by scheduled trips.
SELECT
    r.route_id,
    r.route_short_name,
    COUNT(t.trip_id) AS scheduled_trips
FROM routes r
JOIN trips t
    ON r.route_id = t.route_id
GROUP BY
    r.route_id,
    r.route_short_name
ORDER BY scheduled_trips DESC, r.route_id
LIMIT 20;

-- 4.3 Stops and scheduled visits per route.
SELECT
    t.route_id,
    r.route_short_name,
    COUNT(DISTINCT st.stop_id) AS stops_on_route,
    COUNT(*) AS scheduled_stop_visits
FROM trips t
JOIN routes r
    ON t.route_id = r.route_id
JOIN stop_times st
    ON t.trip_id = st.trip_id
GROUP BY
    t.route_id,
    r.route_short_name
ORDER BY scheduled_stop_visits DESC, t.route_id;

-- 4.4 Top routes by scheduled stop visits.
SELECT
    t.route_id,
    r.route_short_name,
    COUNT(*) AS scheduled_stop_visits
FROM trips t
JOIN routes r
    ON t.route_id = r.route_id
JOIN stop_times st
    ON t.trip_id = st.trip_id
GROUP BY
    t.route_id,
    r.route_short_name
ORDER BY scheduled_stop_visits DESC, t.route_id
LIMIT 20;

-- ============================================================
-- 5. STOP ANALYSIS
-- ============================================================

-- 5.1 Stops served by the most distinct routes.
SELECT
    s.stop_id,
    s.stop_name,
    COUNT(DISTINCT t.route_id) AS routes_serving_stop
FROM stops s
JOIN stop_times st
    ON s.stop_id = st.stop_id
JOIN trips t
    ON st.trip_id = t.trip_id
GROUP BY
    s.stop_id,
    s.stop_name
ORDER BY routes_serving_stop DESC, s.stop_id
LIMIT 20;

-- 5.2 Stops with the most scheduled visits.
SELECT
    s.stop_id,
    s.stop_name,
    COUNT(*) AS scheduled_visits,
    COUNT(DISTINCT t.route_id) AS routes_serving_stop,
    COUNT(DISTINCT st.trip_id) AS trips_serving_stop
FROM stops s
JOIN stop_times st
    ON s.stop_id = st.stop_id
JOIN trips t
    ON st.trip_id = t.trip_id
GROUP BY
    s.stop_id,
    s.stop_name
ORDER BY scheduled_visits DESC, s.stop_id
LIMIT 20;

-- 5.3 Stop coverage distribution.
SELECT
    route_count AS routes_serving_stop,
    COUNT(*) AS number_of_stops
FROM (
    SELECT
        s.stop_id,
        COUNT(DISTINCT t.route_id) AS route_count
    FROM stops s
    LEFT JOIN stop_times st
        ON s.stop_id = st.stop_id
    LEFT JOIN trips t
        ON st.trip_id = t.trip_id
    GROUP BY s.stop_id
)
GROUP BY route_count
ORDER BY route_count;

-- ============================================================
-- 6. SCHEDULED HEADWAY ANALYSIS
-- ============================================================

-- 6.1 Detailed scheduled gaps using LAG().
--
-- Headway is calculated for the same route, direction, and stop.
-- These are planned schedule gaps, not observed operational gaps.
WITH ordered AS (
    SELECT
        t.route_id,
        t.direction_id,
        st.stop_id,
        st.trip_id,
        st.arrival_seconds,
        LAG(st.arrival_seconds) OVER (
            PARTITION BY
                t.route_id,
                t.direction_id,
                st.stop_id
            ORDER BY
                st.arrival_seconds,
                st.trip_id
        ) AS previous_arrival_seconds
    FROM stop_times st
    JOIN trips t
        ON st.trip_id = t.trip_id
)
SELECT
    route_id,
    direction_id,
    stop_id,
    trip_id,
    arrival_seconds,
    previous_arrival_seconds,
    ROUND(
        (arrival_seconds - previous_arrival_seconds) / 60.0,
        2
    ) AS headway_minutes
FROM ordered
WHERE previous_arrival_seconds IS NOT NULL
ORDER BY
    route_id,
    direction_id,
    stop_id,
    arrival_seconds,
    trip_id;

-- 6.2 Headway statistics by route, direction, and stop.
WITH ordered AS (
    SELECT
        t.route_id,
        t.direction_id,
        st.stop_id,
        st.trip_id,
        st.arrival_seconds,
        LAG(st.arrival_seconds) OVER (
            PARTITION BY
                t.route_id,
                t.direction_id,
                st.stop_id
            ORDER BY
                st.arrival_seconds,
                st.trip_id
        ) AS previous_arrival_seconds
    FROM stop_times st
    JOIN trips t
        ON st.trip_id = t.trip_id
),
headways AS (
    SELECT
        route_id,
        direction_id,
        stop_id,
        (arrival_seconds - previous_arrival_seconds) / 60.0
            AS headway_minutes
    FROM ordered
    WHERE previous_arrival_seconds IS NOT NULL
      AND arrival_seconds >= previous_arrival_seconds
)
SELECT
    route_id,
    direction_id,
    stop_id,
    COUNT(*) AS scheduled_gaps,
    ROUND(AVG(headway_minutes), 2) AS average_headway_minutes,
    ROUND(MIN(headway_minutes), 2) AS minimum_headway_minutes,
    ROUND(MAX(headway_minutes), 2) AS maximum_headway_minutes
FROM headways
GROUP BY
    route_id,
    direction_id,
    stop_id
ORDER BY
    average_headway_minutes,
    route_id,
    stop_id;

-- 6.3 Overall headway summary.
WITH ordered AS (
    SELECT
        t.route_id,
        t.direction_id,
        st.stop_id,
        st.arrival_seconds,
        LAG(st.arrival_seconds) OVER (
            PARTITION BY
                t.route_id,
                t.direction_id,
                st.stop_id
            ORDER BY
                st.arrival_seconds,
                st.trip_id
        ) AS previous_arrival_seconds
    FROM stop_times st
    JOIN trips t
        ON st.trip_id = t.trip_id
),
headways AS (
    SELECT
        (arrival_seconds - previous_arrival_seconds) / 60.0
            AS headway_minutes
    FROM ordered
    WHERE previous_arrival_seconds IS NOT NULL
      AND arrival_seconds >= previous_arrival_seconds
)
SELECT
    COUNT(*) AS valid_scheduled_gaps,
    ROUND(MIN(headway_minutes), 2) AS minimum_headway_minutes,
    ROUND(AVG(headway_minutes), 2) AS average_headway_minutes,
    ROUND(MAX(headway_minutes), 2) AS maximum_headway_minutes
FROM headways;

-- 6.4 Headway distribution by practical interval.
WITH ordered AS (
    SELECT
        t.route_id,
        t.direction_id,
        st.stop_id,
        st.arrival_seconds,
        LAG(st.arrival_seconds) OVER (
            PARTITION BY
                t.route_id,
                t.direction_id,
                st.stop_id
            ORDER BY
                st.arrival_seconds,
                st.trip_id
        ) AS previous_arrival_seconds
    FROM stop_times st
    JOIN trips t
        ON st.trip_id = t.trip_id
),
headways AS (
    SELECT
        (arrival_seconds - previous_arrival_seconds) / 60.0
            AS headway_minutes
    FROM ordered
    WHERE previous_arrival_seconds IS NOT NULL
      AND arrival_seconds >= previous_arrival_seconds
)
SELECT
    CASE
        WHEN headway_minutes < 5 THEN '<5 min'
        WHEN headway_minutes < 10 THEN '5-9 min'
        WHEN headway_minutes < 20 THEN '10-19 min'
        WHEN headway_minutes < 30 THEN '20-29 min'
        WHEN headway_minutes < 60 THEN '30-59 min'
        WHEN headway_minutes < 120 THEN '60-119 min'
        ELSE '120+ min'
    END AS headway_band,
    COUNT(*) AS scheduled_gaps
FROM headways
GROUP BY headway_band
ORDER BY
    CASE headway_band
        WHEN '<5 min' THEN 1
        WHEN '5-9 min' THEN 2
        WHEN '10-19 min' THEN 3
        WHEN '20-29 min' THEN 4
        WHEN '30-59 min' THEN 5
        WHEN '60-119 min' THEN 6
        WHEN '120+ min' THEN 7
    END;

-- ============================================================
-- 7. TIME-OF-DAY ANALYSIS
-- ============================================================

-- Arrival distribution using the same service-period definitions
-- used by the Python cleaning pipeline.
SELECT
    CASE
        WHEN (arrival_seconds % 86400) / 3600.0 <= 5
            THEN 'Early/Late'
        WHEN (arrival_seconds % 86400) / 3600.0 <= 8
            THEN 'Morning peak'
        WHEN (arrival_seconds % 86400) / 3600.0 <= 15
            THEN 'Midday'
        WHEN (arrival_seconds % 86400) / 3600.0 <= 19
            THEN 'Evening peak'
        ELSE 'Night'
    END AS service_period,
    COUNT(*) AS scheduled_stop_visits
FROM stop_times
GROUP BY service_period
ORDER BY
    CASE service_period
        WHEN 'Early/Late' THEN 1
        WHEN 'Morning peak' THEN 2
        WHEN 'Midday' THEN 3
        WHEN 'Evening peak' THEN 4
        WHEN 'Night' THEN 5
    END;

-- Scheduled stop visits by hour of service day.
SELECT
    (arrival_seconds % 86400) / 3600 AS service_hour,
    COUNT(*) AS scheduled_stop_visits
FROM stop_times
GROUP BY service_hour
ORDER BY service_hour;

-- ============================================================
-- 8. OVERNIGHT SERVICE
-- ============================================================

-- Distribution of scheduled stop visits by GTFS service-day offset.
SELECT
    arrival_day_offset,
    COUNT(*) AS scheduled_stop_visits
FROM stop_times
GROUP BY arrival_day_offset
ORDER BY arrival_day_offset;

-- Overnight service by route.
SELECT
    t.route_id,
    r.route_short_name,
    COUNT(*) AS overnight_stop_visits
FROM stop_times st
JOIN trips t
    ON st.trip_id = t.trip_id
JOIN routes r
    ON t.route_id = r.route_id
WHERE st.arrival_day_offset > 0
GROUP BY
    t.route_id,
    r.route_short_name
ORDER BY overnight_stop_visits DESC, t.route_id;

-- Trips containing at least one overnight arrival.
SELECT
    COUNT(DISTINCT st.trip_id) AS trips_with_overnight_arrivals
FROM stop_times st
WHERE st.arrival_day_offset > 0;

-- ============================================================
-- 9. GEOGRAPHIC / STOP LOCATION ANALYSIS
-- ============================================================

-- Basic geographic extent of the cleaned stop network.
SELECT
    ROUND(MIN(stop_lat), 6) AS minimum_latitude,
    ROUND(MAX(stop_lat), 6) AS maximum_latitude,
    ROUND(MIN(stop_lon), 6) AS minimum_longitude,
    ROUND(MAX(stop_lon), 6) AS maximum_longitude
FROM stops;

-- Stops with their scheduled activity for mapping/export.
SELECT
    s.stop_id,
    s.stop_name,
    s.stop_lat,
    s.stop_lon,
    COUNT(st.trip_id) AS scheduled_visits,
    COUNT(DISTINCT t.route_id) AS routes_serving_stop
FROM stops s
LEFT JOIN stop_times st
    ON s.stop_id = st.stop_id
LEFT JOIN trips t
    ON st.trip_id = t.trip_id
GROUP BY
    s.stop_id,
    s.stop_name,
    s.stop_lat,
    s.stop_lon
ORDER BY scheduled_visits DESC, s.stop_id;

-- ============================================================
-- 10. DATA-QUALITY / INTEGRITY CHECKS
-- ============================================================

-- 10.1 Orphan trips.
SELECT COUNT(*) AS orphan_trips
FROM trips t
LEFT JOIN routes r
    ON t.route_id = r.route_id
WHERE r.route_id IS NULL;

-- 10.2 Trips with invalid service references.
SELECT COUNT(*) AS orphan_service_references
FROM trips t
LEFT JOIN calendar c
    ON t.service_id = c.service_id
WHERE c.service_id IS NULL;

-- 10.3 Orphan stop-time trip references.
SELECT COUNT(*) AS orphan_stop_time_trips
FROM stop_times st
LEFT JOIN trips t
    ON st.trip_id = t.trip_id
WHERE t.trip_id IS NULL;

-- 10.4 Orphan stop-time stop references.
SELECT COUNT(*) AS orphan_stop_time_stops
FROM stop_times st
LEFT JOIN stops s
    ON st.stop_id = s.stop_id
WHERE s.stop_id IS NULL;

-- 10.5 Invalid geographic coordinates against the project's cleaning bounds.
SELECT COUNT(*) AS invalid_coordinates
FROM stops
WHERE stop_lat IS NULL
   OR stop_lon IS NULL
   OR stop_lat NOT BETWEEN 18.0 AND 19.0
   OR stop_lon NOT BETWEEN 73.2 AND 74.6;

-- 10.6 Invalid negative scheduled headways.
WITH ordered AS (
    SELECT
        t.route_id,
        t.direction_id,
        st.stop_id,
        st.trip_id,
        st.arrival_seconds,
        LAG(st.arrival_seconds) OVER (
            PARTITION BY
                t.route_id,
                t.direction_id,
                st.stop_id
            ORDER BY
                st.arrival_seconds,
                st.trip_id
        ) AS previous_arrival_seconds
    FROM stop_times st
    JOIN trips t
        ON st.trip_id = t.trip_id
)
SELECT COUNT(*) AS negative_headways
FROM ordered
WHERE previous_arrival_seconds IS NOT NULL
  AND arrival_seconds < previous_arrival_seconds;

-- 10.7 Zero scheduled headways.
WITH ordered AS (
    SELECT
        t.route_id,
        t.direction_id,
        st.stop_id,
        st.trip_id,
        st.arrival_seconds,
        LAG(st.arrival_seconds) OVER (
            PARTITION BY
                t.route_id,
                t.direction_id,
                st.stop_id
            ORDER BY
                st.arrival_seconds,
                st.trip_id
        ) AS previous_arrival_seconds
    FROM stop_times st
    JOIN trips t
        ON st.trip_id = t.trip_id
)
SELECT COUNT(*) AS zero_headways
FROM ordered
WHERE previous_arrival_seconds IS NOT NULL
  AND arrival_seconds = previous_arrival_seconds;

-- 10.8 Duplicate route IDs.
SELECT
    route_id,
    COUNT(*) AS duplicate_count
FROM routes
GROUP BY route_id
HAVING COUNT(*) > 1;

-- 10.9 Duplicate stop IDs.
SELECT
    stop_id,
    COUNT(*) AS duplicate_count
FROM stops
GROUP BY stop_id
HAVING COUNT(*) > 1;

-- 10.10 Duplicate trip IDs.
SELECT
    trip_id,
    COUNT(*) AS duplicate_count
FROM trips
GROUP BY trip_id
HAVING COUNT(*) > 1;

-- 10.11 Duplicate stop-time keys.
SELECT
    trip_id,
    stop_sequence,
    COUNT(*) AS duplicate_count
FROM stop_times
GROUP BY
    trip_id,
    stop_sequence
HAVING COUNT(*) > 1;

-- ============================================================
-- 11. CROSS-CHECK QUERIES FOR PYTHON / EDA
-- ============================================================

-- These queries are intended to make cross-validation easy.
-- Compare these outputs with the Python EDA and cleaned CSVs.

-- 11.1 Core counts.
SELECT 'routes' AS metric, COUNT(*) AS value FROM routes
UNION ALL
SELECT 'stops', COUNT(*) FROM stops
UNION ALL
SELECT 'trips', COUNT(*) FROM trips
UNION ALL
SELECT 'stop_times', COUNT(*) FROM stop_times
UNION ALL
SELECT 'calendar', COUNT(*) FROM calendar
UNION ALL
SELECT 'calendar_dates', COUNT(*) FROM calendar_dates;

-- 11.2 Scheduled visits per trip.
SELECT
    ROUND(
        COUNT(*) * 1.0 / NULLIF(COUNT(DISTINCT trip_id), 0),
        2
    ) AS scheduled_visits_per_trip
FROM stop_times;

-- 11.3 Overnight record summary.
SELECT
    COUNT(*) AS total_stop_times,
    SUM(CASE WHEN arrival_day_offset > 0 THEN 1 ELSE 0 END)
        AS overnight_stop_times,
    ROUND(
        SUM(CASE WHEN arrival_day_offset > 0 THEN 1 ELSE 0 END) * 100.0
        / NULLIF(COUNT(*), 0),
        3
    ) AS overnight_percentage,
    MAX(arrival_day_offset) AS maximum_arrival_day_offset
FROM stop_times;

-- 11.4 Headway cross-check.
WITH ordered AS (
    SELECT
        t.route_id,
        t.direction_id,
        st.stop_id,
        st.arrival_seconds,
        LAG(st.arrival_seconds) OVER (
            PARTITION BY
                t.route_id,
                t.direction_id,
                st.stop_id
            ORDER BY
                st.arrival_seconds,
                st.trip_id
        ) AS previous_arrival_seconds
    FROM stop_times st
    JOIN trips t
        ON st.trip_id = t.trip_id
),
headways AS (
    SELECT
        (arrival_seconds - previous_arrival_seconds) / 60.0
            AS headway_minutes
    FROM ordered
    WHERE previous_arrival_seconds IS NOT NULL
)
SELECT
    COUNT(*) AS valid_headways,
    ROUND(MIN(headway_minutes), 2) AS minimum_headway_minutes,
    ROUND(AVG(headway_minutes), 2) AS average_headway_minutes,
    ROUND(MAX(headway_minutes), 2) AS maximum_headway_minutes,
    SUM(CASE WHEN headway_minutes < 0 THEN 1 ELSE 0 END)
        AS negative_headways,
    SUM(CASE WHEN headway_minutes = 0 THEN 1 ELSE 0 END)
        AS zero_headways
FROM headways;
