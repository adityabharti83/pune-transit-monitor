"""Create and populate the local SQLite database from cleaned GTFS CSV files."""

from __future__ import annotations

import argparse
from pathlib import Path
import sqlite3

import pandas as pd


PROJECT_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_DATABASE = PROJECT_ROOT / "data" / "pune_transit.db"
DEFAULT_CLEANED_DIR = PROJECT_ROOT / "data" / "cleaned"
SCHEMA_PATH = PROJECT_ROOT / "sql" / "schema.sql"

TABLES_IN_LOAD_ORDER = ("routes", "stops", "calendar", "trips", "stop_times", "calendar_dates")
TABLES_IN_DELETE_ORDER = tuple(reversed(TABLES_IN_LOAD_ORDER))


def build_database(database_path: Path, cleaned_dir: Path) -> dict[str, int]:
    """Apply the schema and replace table contents with the current cleaned CSVs."""
    database_path.parent.mkdir(parents=True, exist_ok=True)
    with sqlite3.connect(database_path) as connection:
        connection.execute("PRAGMA foreign_keys = ON")
        connection.executescript(SCHEMA_PATH.read_text(encoding="utf-8"))

        # Child tables must be emptied before their parent tables.
        for table in TABLES_IN_DELETE_ORDER:
            connection.execute(f"DELETE FROM {table}")

        loaded_rows = {}
        for table in TABLES_IN_LOAD_ORDER:
            csv_path = cleaned_dir / f"{table}_clean.csv"
            if not csv_path.exists():
                continue
            dataframe = pd.read_csv(csv_path)
            dataframe.to_sql(table, connection, if_exists="append", index=False, chunksize=1_000)
            loaded_rows[table] = len(dataframe)
    return loaded_rows


def main() -> None:
    parser = argparse.ArgumentParser(description="Build the local Pune transit SQLite database.")
    parser.add_argument("--database", type=Path, default=DEFAULT_DATABASE)
    parser.add_argument("--cleaned-dir", type=Path, default=DEFAULT_CLEANED_DIR)
    args = parser.parse_args()

    loaded_rows = build_database(args.database, args.cleaned_dir)
    print(f"SQLite database created: {args.database}")
    for table, count in loaded_rows.items():
        print(f"- {table}: {count:,} rows")


if __name__ == "__main__":
    main()
