"""Clean local GTFS data into small, analysis-ready CSV datasets.

Run this after placing a GTFS ZIP in data/raw. The script only reads and writes
local files; it does not use cloud services or require credentials.
"""

from __future__ import annotations

import argparse
from pathlib import Path
import re
from typing import Dict
import zipfile

import numpy as np
import pandas as pd

PROJECT_ROOT = Path(__file__).resolve().parents[1]
RAW_DIR = PROJECT_ROOT / "data" / "raw"
CLEANED_DIR = PROJECT_ROOT / "data" / "cleaned"
TIME_PATTERN = re.compile(r"^(\d{1,2}):([0-5]\d):([0-5]\d)$")


def gtfs_time_to_seconds(value: object) -> float:
    """Convert GTFS HH:MM:SS to service-day seconds; 25:10:00 is valid."""
    match = TIME_PATTERN.match(str(value).strip())
    if not match:
        return np.nan
    hours, minutes, seconds = map(int, match.groups())
    return hours * 3600 + minutes * 60 + seconds


def _read_from_zip(zip_path: Path, filename: str) -> pd.DataFrame | None:
    with zipfile.ZipFile(zip_path) as archive:
        member = next((name for name in archive.namelist() if Path(name).name == filename), None)
        if member is None:
            return None
        with archive.open(member) as source:
            return pd.read_csv(source, dtype=str, encoding="utf-8-sig")


def load_raw_gtfs(zip_path: Path) -> Dict[str, pd.DataFrame]:
    """Load the GTFS files relevant to local analysis from one ZIP archive."""
    if not zip_path.exists():
        raise FileNotFoundError(f"Raw GTFS ZIP not found: {zip_path}")
    if not zipfile.is_zipfile(zip_path):
        raise ValueError(f"Not a GTFS ZIP archive: {zip_path}")
    tables = {}
    for name in ("routes", "stops", "trips", "stop_times", "calendar", "calendar_dates"):
        dataframe = _read_from_zip(zip_path, f"{name}.txt")
        if dataframe is not None:
            tables[name] = dataframe
    required = {"routes", "stops", "trips", "stop_times"}
    missing = required - tables.keys()
    if missing:
        raise ValueError(f"Raw feed is missing required tables: {sorted(missing)}")
    return tables


def _require_columns(dataframe: pd.DataFrame, columns: set[str], table_name: str) -> None:
    missing = columns - set(dataframe.columns)
    if missing:
        raise ValueError(f"{table_name}.txt is missing columns: {sorted(missing)}")


def _clean_text(dataframe: pd.DataFrame) -> pd.DataFrame:
    cleaned = dataframe.copy()
    for column in cleaned.columns:
        if cleaned[column].dtype == object:
            cleaned[column] = cleaned[column].str.strip().replace("", pd.NA)
    return cleaned


def _clean_dates(series: pd.Series) -> pd.Series:
    return pd.to_datetime(series, format="%Y%m%d", errors="coerce").dt.strftime("%Y-%m-%d")


def clean_tables(raw: Dict[str, pd.DataFrame]) -> Dict[str, pd.DataFrame]:
    """Return consistent GTFS tables plus one flat schedule-analysis dataset."""
    routes = _clean_text(raw["routes"])
    _require_columns(routes, {"route_id", "route_short_name", "route_type"}, "routes")
    routes = routes.reindex(columns=["route_id", "route_short_name", "route_long_name", "route_desc", "route_type", "route_color"])
    routes = routes.dropna(subset=["route_id"]).drop_duplicates("route_id").copy()
    routes["route_short_name"] = routes["route_short_name"].fillna(routes["route_id"])
    routes["route_type"] = pd.to_numeric(routes["route_type"], errors="coerce").astype("Int64")

    stops = _clean_text(raw["stops"])
    _require_columns(stops, {"stop_id", "stop_lat", "stop_lon"}, "stops")
    stops = stops.reindex(columns=["stop_id", "stop_name", "stop_lat", "stop_lon", "stop_desc", "zone_id"])
    stops["stop_lat"] = pd.to_numeric(stops["stop_lat"], errors="coerce")
    stops["stop_lon"] = pd.to_numeric(stops["stop_lon"], errors="coerce")
    stops = stops.dropna(subset=["stop_id", "stop_lat", "stop_lon"]).drop_duplicates("stop_id")
    stops = stops[stops["stop_lat"].between(18.0, 19.0) & stops["stop_lon"].between(73.2, 74.6)].copy()
    stops["stop_name"] = stops["stop_name"].fillna("Unknown stop")

    trips = _clean_text(raw["trips"])
    _require_columns(trips, {"trip_id", "route_id", "service_id"}, "trips")
    trips = trips.reindex(columns=["trip_id", "route_id", "service_id", "trip_headsign", "direction_id"])
    trips = trips.dropna(subset=["trip_id", "route_id", "service_id"]).drop_duplicates("trip_id")
    trips = trips[trips["route_id"].isin(routes["route_id"])].copy()
    trips["direction_id"] = pd.to_numeric(trips["direction_id"], errors="coerce").astype("Int64")

    stop_times = _clean_text(raw["stop_times"])
    required_stop_times = {"trip_id", "stop_id", "arrival_time", "departure_time", "stop_sequence"}
    _require_columns(stop_times, required_stop_times, "stop_times")
    stop_times = stop_times.reindex(columns=["trip_id", "stop_id", "arrival_time", "departure_time", "stop_sequence", "stop_headsign", "pickup_type", "drop_off_type"])
    stop_times["arrival_seconds"] = stop_times["arrival_time"].map(gtfs_time_to_seconds)
    stop_times["departure_seconds"] = stop_times["departure_time"].map(gtfs_time_to_seconds)
    stop_times["stop_sequence"] = pd.to_numeric(stop_times["stop_sequence"], errors="coerce")
    stop_times = stop_times.dropna(subset=["trip_id", "stop_id", "arrival_seconds", "departure_seconds", "stop_sequence"])
    stop_times["arrival_seconds"] = stop_times["arrival_seconds"].astype("int64")
    stop_times["departure_seconds"] = stop_times["departure_seconds"].astype("int64")
    stop_times["stop_sequence"] = stop_times["stop_sequence"].astype("int64")
    stop_times = stop_times.drop_duplicates(["trip_id", "stop_sequence"])
    stop_times = stop_times[stop_times["trip_id"].isin(trips["trip_id"]) & stop_times["stop_id"].isin(stops["stop_id"])].copy()
    stop_times["arrival_day_offset"] = stop_times["arrival_seconds"] // 86400

    cleaned = {"routes": routes, "stops": stops, "trips": trips, "stop_times": stop_times}
    if "calendar" in raw:
        calendar = _clean_text(raw["calendar"])
        _require_columns(calendar, {"service_id", "start_date", "end_date"}, "calendar")
        day_columns = ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"]
        calendar = calendar.reindex(columns=["service_id", *day_columns, "start_date", "end_date"])
        calendar = calendar.dropna(subset=["service_id"]).drop_duplicates("service_id")
        for day in day_columns:
            calendar[day] = pd.to_numeric(calendar[day], errors="coerce").fillna(0).astype("int64")
        calendar["start_date"] = _clean_dates(calendar["start_date"])
        calendar["end_date"] = _clean_dates(calendar["end_date"])
        cleaned["calendar"] = calendar
    if "calendar_dates" in raw:
        calendar_dates = _clean_text(raw["calendar_dates"])
        _require_columns(calendar_dates, {"service_id", "date", "exception_type"}, "calendar_dates")
        calendar_dates = calendar_dates.reindex(columns=["service_id", "date", "exception_type"])
        calendar_dates["date"] = _clean_dates(calendar_dates["date"])
        calendar_dates["exception_type"] = pd.to_numeric(calendar_dates["exception_type"], errors="coerce")
        calendar_dates = calendar_dates.dropna(subset=["service_id", "date", "exception_type"]).drop_duplicates(["service_id", "date"])
        calendar_dates["exception_type"] = calendar_dates["exception_type"].astype("int64")
        cleaned["calendar_dates"] = calendar_dates

    analysis = stop_times.merge(trips, on="trip_id", how="left").merge(routes, on="route_id", how="left").merge(stops, on="stop_id", how="left")
    analysis = analysis.sort_values(["route_id", "direction_id", "stop_id", "arrival_seconds", "trip_id"]).copy()
    group_columns = ["route_id", "direction_id", "stop_id"]
    analysis["previous_arrival_seconds"] = analysis.groupby(group_columns, dropna=False)["arrival_seconds"].shift()
    analysis["headway_minutes"] = (analysis["arrival_seconds"] - analysis["previous_arrival_seconds"]) / 60
    hour = (analysis["arrival_seconds"] % 86400) // 3600
    analysis["service_period"] = pd.cut(hour, bins=[-1, 5, 8, 15, 19, 23], labels=["Early/Late", "Morning peak", "Midday", "Evening peak", "Night"])
    cleaned["transit_schedule_analysis"] = analysis
    return cleaned


def save_cleaned_tables(tables: Dict[str, pd.DataFrame], output_dir: Path = CLEANED_DIR) -> Dict[str, Path]:
    output_dir.mkdir(parents=True, exist_ok=True)
    paths = {}
    for name, dataframe in tables.items():
        path = output_dir / f"{name}_clean.csv"
        dataframe.to_csv(path, index=False)
        paths[name] = path
    return paths


def main() -> None:
    parser = argparse.ArgumentParser(description="Clean a local GTFS ZIP for analysis.")
    parser.add_argument("--input", type=Path, default=RAW_DIR / "pmpml_gtfs.zip")
    parser.add_argument("--output-dir", type=Path, default=CLEANED_DIR)
    args = parser.parse_args()
    cleaned = clean_tables(load_raw_gtfs(args.input))
    paths = save_cleaned_tables(cleaned, args.output_dir)
    print("Cleaned datasets created:")
    for name, path in paths.items():
        print(f"- {name}: {len(cleaned[name]):,} rows -> {path}")


if __name__ == "__main__":
    main()
