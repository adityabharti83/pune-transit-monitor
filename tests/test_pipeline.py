from __future__ import annotations

from io import BytesIO
from pathlib import Path
import zipfile

import pandas as pd

from scripts.clean_data import clean_tables, gtfs_time_to_seconds, load_raw_gtfs, save_cleaned_tables
from scripts.download_data import verify_gtfs_zip


def raw_tables() -> dict[str, pd.DataFrame]:
    return {
        "routes": pd.DataFrame({"route_id": ["R1", "R1"], "route_short_name": ["1", "1"], "route_type": ["3", "3"]}),
        "stops": pd.DataFrame({"stop_id": ["S1", "S2", "BAD"], "stop_name": ["Central", "Central", "Outside"],
                               "stop_lat": ["18.52", "18.52", "10"], "stop_lon": ["73.85", "73.85", "10"]}),
        "trips": pd.DataFrame({"trip_id": ["T1", "T2", "ORPHAN"], "route_id": ["R1", "R1", "NO_ROUTE"],
                               "service_id": ["WK", "WK", "WK"], "direction_id": ["0", "0", "0"]}),
        "stop_times": pd.DataFrame({"trip_id": ["T1", "T2", "ORPHAN"], "stop_id": ["S1", "S1", "S1"],
                                     "arrival_time": ["25:10:00", "25:40:00", "bad"],
                                     "departure_time": ["25:11:00", "25:41:00", "bad"], "stop_sequence": ["1", "1", "1"]}),
        "calendar": pd.DataFrame({"service_id": ["WK"], "monday": ["1"], "tuesday": ["1"], "wednesday": ["1"],
                                  "thursday": ["1"], "friday": ["1"], "saturday": ["0"], "sunday": ["0"],
                                  "start_date": ["20260101"], "end_date": ["20261231"]}),
    }


def test_gtfs_time_supports_overnight_services():
    assert gtfs_time_to_seconds("25:10:00") == 90600
    assert pd.isna(gtfs_time_to_seconds("25:70:00"))


def test_cleaning_removes_invalid_duplicates_and_orphans():
    cleaned = clean_tables(raw_tables())
    assert cleaned["routes"].route_id.tolist() == ["R1"]
    assert set(cleaned["stops"].stop_id) == {"S1", "S2"}
    assert set(cleaned["trips"].trip_id) == {"T1", "T2"}
    assert set(cleaned["stop_times"].trip_id) == {"T1", "T2"}


def test_analysis_dataset_calculates_headway():
    analysis = clean_tables(raw_tables())["transit_schedule_analysis"]
    assert analysis["headway_minutes"].dropna().tolist() == [30.0]
    assert analysis["arrival_day_offset"].tolist() == [1, 1]


def test_cleaned_csvs_are_written(tmp_path):
    paths = save_cleaned_tables(clean_tables(raw_tables()), tmp_path)
    assert paths["transit_schedule_analysis"].exists()
    assert pd.read_csv(paths["routes"]).shape[0] == 1


def test_local_gtfs_zip_is_verified_and_loaded(tmp_path):
    archive_path = tmp_path / "feed.zip"
    with zipfile.ZipFile(archive_path, "w") as archive:
        for filename in ("routes.txt", "stops.txt", "trips.txt", "stop_times.txt", "calendar.txt"):
            archive.writestr(filename, "column\nvalue\n")
    assert len(verify_gtfs_zip(archive_path)) == 64
    assert set(load_raw_gtfs(archive_path)) >= {"routes", "stops", "trips", "stop_times", "calendar"}
