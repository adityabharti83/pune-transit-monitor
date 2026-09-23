"""Download the public PMPML GTFS ZIP into data/raw for local analysis."""

from __future__ import annotations

import argparse
import hashlib
from pathlib import Path
import zipfile

import requests

PROJECT_ROOT = Path(__file__).resolve().parents[1]
RAW_DIR = PROJECT_ROOT / "data" / "raw"
DEFAULT_URL = "https://raw.githubusercontent.com/croyla/pmpml-gtfs/a9ff0f7a9c750e657ee1186f2a47005020b3f21a/pmpml_gtfs.zip"
DEFAULT_SHA256 = "f62e70b7fe640684cab4560277eb37233e127c2ae865f2642c9afdfae7060d73"
REQUIRED_FILES = {"routes.txt", "stops.txt", "trips.txt", "stop_times.txt", "calendar.txt"}


def verify_gtfs_zip(path: Path, expected_sha256: str | None = None) -> str:
    """Check checksum and required GTFS files, returning the SHA-256 digest."""
    digest = hashlib.sha256(path.read_bytes()).hexdigest()
    if expected_sha256 and digest != expected_sha256:
        raise ValueError("Checksum mismatch: the downloaded file is not the expected feed version.")
    if not zipfile.is_zipfile(path):
        raise ValueError("The downloaded file is not a ZIP archive.")
    with zipfile.ZipFile(path) as archive:
        names = {Path(member).name for member in archive.namelist()}
    missing = REQUIRED_FILES - names
    if missing:
        raise ValueError(f"The ZIP is missing required GTFS files: {sorted(missing)}")
    return digest


def download_gtfs(url: str, destination: Path, expected_sha256: str | None = None) -> str:
    """Download one GTFS archive locally; no cloud storage is used."""
    destination.parent.mkdir(parents=True, exist_ok=True)
    digest = hashlib.sha256()
    try:
        with requests.get(url, stream=True, timeout=(10, 120)) as response:
            response.raise_for_status()
            with destination.open("wb") as output:
                for chunk in response.iter_content(chunk_size=1024 * 1024):
                    if chunk:
                        output.write(chunk)
                        digest.update(chunk)
    except requests.RequestException as error:
        raise RuntimeError(f"Download failed: {error}") from error
    checksum = digest.hexdigest()
    try:
        verify_gtfs_zip(destination, expected_sha256)
    except Exception:
        destination.unlink(missing_ok=True)
        raise
    return checksum


def main() -> None:
    parser = argparse.ArgumentParser(description="Download PMPML GTFS data to data/raw.")
    parser.add_argument("--url", default=DEFAULT_URL, help="Direct GTFS ZIP URL")
    parser.add_argument("--output", type=Path, default=RAW_DIR / "pmpml_gtfs.zip")
    parser.add_argument("--sha256", default=DEFAULT_SHA256, help="Expected SHA-256; use an empty value to skip pinning")
    parser.add_argument("--force", action="store_true", help="Download again even if a valid local ZIP exists")
    args = parser.parse_args()
    expected = args.sha256 or None

    if args.output.exists() and not args.force:
        checksum = verify_gtfs_zip(args.output, expected)
        print(f"Using existing GTFS file: {args.output} ({checksum})")
        return
    checksum = download_gtfs(args.url, args.output, expected)
    print(f"Downloaded GTFS file: {args.output} ({checksum})")


if __name__ == "__main__":
    main()
