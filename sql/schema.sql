-- Optional SQLite schema for the cleaned GTFS CSV files.

PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS routes (
    route_id TEXT PRIMARY KEY, route_short_name TEXT, route_long_name TEXT,
    route_desc TEXT, route_type INTEGER, route_color TEXT
);
CREATE TABLE IF NOT EXISTS stops (
    stop_id TEXT PRIMARY KEY, stop_name TEXT, stop_lat REAL, stop_lon REAL,
    stop_desc TEXT, zone_id TEXT
);
CREATE TABLE IF NOT EXISTS calendar (
    service_id TEXT PRIMARY KEY, monday INTEGER, tuesday INTEGER, wednesday INTEGER,
    thursday INTEGER, friday INTEGER, saturday INTEGER, sunday INTEGER,
    start_date TEXT, end_date TEXT
);
CREATE TABLE IF NOT EXISTS trips (
    trip_id TEXT PRIMARY KEY, route_id TEXT NOT NULL, service_id TEXT NOT NULL,
    trip_headsign TEXT, direction_id INTEGER,
    FOREIGN KEY (route_id) REFERENCES routes(route_id),
    FOREIGN KEY (service_id) REFERENCES calendar(service_id)
);
CREATE TABLE IF NOT EXISTS stop_times (
    trip_id TEXT NOT NULL, stop_id TEXT NOT NULL, arrival_time TEXT NOT NULL,
    departure_time TEXT NOT NULL, stop_sequence INTEGER NOT NULL,
    arrival_seconds INTEGER NOT NULL, departure_seconds INTEGER NOT NULL,
    arrival_day_offset INTEGER NOT NULL, stop_headsign TEXT, pickup_type TEXT,
    drop_off_type TEXT, PRIMARY KEY (trip_id, stop_sequence),
    FOREIGN KEY (trip_id) REFERENCES trips(trip_id), FOREIGN KEY (stop_id) REFERENCES stops(stop_id)
);
CREATE TABLE IF NOT EXISTS calendar_dates (
    service_id TEXT NOT NULL, date TEXT NOT NULL, exception_type INTEGER NOT NULL,
    PRIMARY KEY (service_id, date), FOREIGN KEY (service_id) REFERENCES calendar(service_id)
);
CREATE INDEX IF NOT EXISTS idx_trips_route ON trips(route_id);
CREATE INDEX IF NOT EXISTS idx_stop_times_stop ON stop_times(stop_id);

-- Total routes, stops, and trips
SELECT (SELECT COUNT(*) FROM routes) AS total_routes,
       (SELECT COUNT(*) FROM stops) AS total_stops,
       (SELECT COUNT(*) FROM trips) AS total_trips;

-- Trips per route
SELECT r.route_id, r.route_short_name, COUNT(t.trip_id) AS trips
FROM routes r LEFT JOIN trips t USING (route_id)
GROUP BY r.route_id, r.route_short_name ORDER BY trips DESC;

-- Stops and scheduled visits per route
SELECT t.route_id, COUNT(DISTINCT st.stop_id) AS stops_on_route,
       COUNT(*) AS scheduled_stop_visits
FROM trips t JOIN stop_times st USING (trip_id)
GROUP BY t.route_id ORDER BY scheduled_stop_visits DESC;

-- Stops served by the most distinct routes
SELECT s.stop_id, s.stop_name, COUNT(DISTINCT t.route_id) AS routes_serving_stop
FROM stops s JOIN stop_times st USING (stop_id) JOIN trips t USING (trip_id)
GROUP BY s.stop_id, s.stop_name ORDER BY routes_serving_stop DESC;

-- Scheduled headway in minutes by route, direction, and stop
WITH ordered AS (
    SELECT t.route_id, t.direction_id, st.stop_id, st.trip_id, st.arrival_seconds,
           LAG(st.arrival_seconds) OVER (
               PARTITION BY t.route_id, t.direction_id, st.stop_id
               ORDER BY st.arrival_seconds, st.trip_id
           ) AS previous_arrival_seconds
    FROM stop_times st JOIN trips t USING (trip_id)
)
SELECT route_id, direction_id, stop_id,
       ROUND(AVG((arrival_seconds - previous_arrival_seconds) / 60.0), 2) AS average_headway_minutes
FROM ordered WHERE previous_arrival_seconds IS NOT NULL
GROUP BY route_id, direction_id, stop_id ORDER BY average_headway_minutes;


