"""Build a local SQLite database from the cleaned GTFS CSV outputs."""

from __future__ import annotations

import argparse
from pathlib import Path
import sqlite3

import pandas as pd

PROJECT_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_DATABASE = PROJECT_ROOT / "data" / "pune_transit.db"
DEFAULT_CLEANED_DIR = PROJECT_ROOT / "data" / "cleaned"
SCHEMA_PATH = PROJECT_ROOT / "sql" / "schema.sql"

REQUIRED_TABLES = ("routes", "stops", "calendar", "trips", "stop_times")
OPTIONAL_TABLES = ("calendar_dates",)
DELETE_ORDER = ("calendar_dates", "stop_times", "trips", "calendar", "stops", "routes")


def build_database(database_path: Path, cleaned_dir: Path) -> dict[str, int]:
    """Create tables, replace their data, and return rows imported per table."""
    missing = [name for name in REQUIRED_TABLES if not (cleaned_dir / f"{name}_clean.csv").exists()]
    if missing:
        raise FileNotFoundError(
            "Missing cleaned CSV files: " + ", ".join(f"{name}_clean.csv" for name in missing)
        )

    database_path.parent.mkdir(parents=True, exist_ok=True)
    with sqlite3.connect(database_path) as connection:
        connection.execute("PRAGMA foreign_keys = ON")
        connection.executescript(SCHEMA_PATH.read_text(encoding="utf-8"))

        for table in DELETE_ORDER:
            connection.execute(f"DELETE FROM {table}")

        imported: dict[str, int] = {}
        for table in (*REQUIRED_TABLES, *OPTIONAL_TABLES):
            csv_path = cleaned_dir / f"{table}_clean.csv"
            if not csv_path.exists():
                continue
            dataframe = pd.read_csv(csv_path)
            dataframe.to_sql(table, connection, if_exists="append", index=False)
            imported[table] = len(dataframe)
    return imported


def main() -> None:
    parser = argparse.ArgumentParser(description="Load cleaned GTFS CSV files into local SQLite.")
    parser.add_argument("--database", type=Path, default=DEFAULT_DATABASE)
    parser.add_argument("--cleaned-dir", type=Path, default=DEFAULT_CLEANED_DIR)
    args = parser.parse_args()

    imported = build_database(args.database, args.cleaned_dir)
    print(f"SQLite database created: {args.database}")
    for table, rows in imported.items():
        print(f"- {table}: {rows:,} rows")


if __name__ == "__main__":
    main()
