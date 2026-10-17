"""
Download U.S. DOT / BTS on-time performance data and load every flight that
touches Charlotte (CLT) into a SQLite database.

Source: Bureau of Transportation Statistics, "Reporting Carrier On-Time
Performance (1987-present)", a public-domain U.S. government dataset.
https://www.transtats.bts.gov/Tables.asp?QO_VQ=EFD

    python load_data.py                          # default: Jun-Aug 2025
    python load_data.py --year 2025 --months 1 2 3 4 5 6 7 8 9 10 11 12
    python load_data.py --zip path/to/file.zip   # a file you downloaded yourself
    python load_data.py --airport ATL            # any other airport works too

Each monthly file is about 30 MB to download. Only CLT rows are kept.
"""

from __future__ import annotations

import argparse
import csv
import io
import sqlite3
import sys
import urllib.request
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent
DB_PATH = ROOT / "data" / "clt_flights.db"
DOWNLOAD_DIR = ROOT / "data" / "raw"
URL = "https://transtats.bts.gov/PREZIP/On_Time_Reporting_Carrier_On_Time_Performance_1987_present_{year}_{month}.zip"

AIRLINES = {
    "AA": "American Airlines", "DL": "Delta Air Lines", "UA": "United Airlines", "WN": "Southwest Airlines",
    "B6": "JetBlue", "AS": "Alaska Airlines", "NK": "Spirit Airlines", "F9": "Frontier Airlines",
    "G4": "Allegiant Air", "HA": "Hawaiian Airlines", "SY": "Sun Country", "MX": "Breeze Airways",
    "OO": "SkyWest Airlines", "YX": "Republic Airways", "MQ": "Envoy Air", "OH": "PSA Airlines",
    "9E": "Endeavor Air", "YV": "Mesa Airlines", "QX": "Horizon Air", "ZW": "Air Wisconsin",
    "G7": "GoJet Airlines", "C5": "CommuteAir", "PT": "Piedmont Airlines", "EV": "ExpressJet",
}


def num(v: str) -> float | None:
    try:
        return float(v) if v not in ("", None) else None
    except ValueError:
        return None


def hour(hhmm: str) -> int | None:
    v = num(hhmm)
    return None if v is None else int(v // 100) % 24


def download(year: int, month: int) -> Path:
    DOWNLOAD_DIR.mkdir(parents=True, exist_ok=True)
    path = DOWNLOAD_DIR / f"ontime_{year}_{month:02d}.zip"
    if path.exists() and path.stat().st_size > 1_000_000:
        print(f"  using cached {path.name}")
        return path
    url = URL.format(year=year, month=month)
    print(f"  downloading {year}-{month:02d} …", end="", flush=True)
    req = urllib.request.Request(url, headers={"User-Agent": "clt-flight-delays-sql (student project)"})
    with urllib.request.urlopen(req, timeout=300) as resp, open(path, "wb") as f:
        while chunk := resp.read(1 << 20):
            f.write(chunk)
            print(".", end="", flush=True)
    print(f" {path.stat().st_size / 1e6:.0f} MB")
    return path


def rows_from_zip(path: Path):
    with zipfile.ZipFile(path) as z:
        name = next(n for n in z.namelist() if n.lower().endswith(".csv"))
        with z.open(name) as raw:
            yield from csv.DictReader(io.TextIOWrapper(raw, encoding="latin-1", newline=""))


def load(con: sqlite3.Connection, rows, airport: str) -> int:
    n = 0
    batch, airports, carriers = [], {}, set()
    for r in rows:
        origin, dest = r.get("Origin"), r.get("Dest")
        if airport not in (origin, dest):
            continue
        carrier = r.get("Reporting_Airline") or r.get("IATA_CODE_Reporting_Airline")
        carriers.add(carrier)
        airports.setdefault(origin, (r.get("OriginCityName"), r.get("OriginState")))
        airports.setdefault(dest, (r.get("DestCityName"), r.get("DestState")))
        batch.append((
            r["FlightDate"], int(r["DayOfWeek"]), carrier, r.get("Flight_Number_Reporting_Airline"),
            r.get("Tail_Number") or None, origin, dest,
            "departure" if origin == airport else "arrival",
            hour(r.get("CRSDepTime")), hour(r.get("CRSArrTime")),
            num(r.get("DepDelay")), num(r.get("ArrDelay")), num(r.get("TaxiOut")),
            int(num(r.get("Cancelled")) or 0), r.get("CancellationCode") or None,
            int(num(r.get("Diverted")) or 0), num(r.get("Distance")),
            num(r.get("CarrierDelay")), num(r.get("WeatherDelay")), num(r.get("NASDelay")),
            num(r.get("SecurityDelay")), num(r.get("LateAircraftDelay")),
        ))
        if len(batch) >= 5000:
            n += flush(con, batch)
    n += flush(con, batch)
    con.executemany("INSERT OR IGNORE INTO airports(code, city, state) VALUES (?,?,?)",
                    [(k, v[0], v[1]) for k, v in airports.items()])
    con.executemany("INSERT OR IGNORE INTO airlines(code, name) VALUES (?,?)",
                    [(c, AIRLINES.get(c, c)) for c in carriers])
    con.commit()
    return n


def flush(con, batch) -> int:
    con.executemany("""INSERT INTO flights(
        flight_date, day_of_week, airline, flight_number, tail_number, origin, dest, direction,
        sched_dep_hour, sched_arr_hour, dep_delay_min, arr_delay_min, taxi_out_min,
        cancelled, cancellation_code, diverted, distance_miles,
        carrier_delay, weather_delay, nas_delay, security_delay, late_aircraft_delay)
        VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)""", batch)
    k = len(batch)
    batch.clear()
    return k


def main():
    ap = argparse.ArgumentParser(description="Load BTS on-time data for one airport into SQLite.")
    ap.add_argument("--year", type=int, default=2025)
    ap.add_argument("--months", type=int, nargs="+", default=[6, 7, 8])
    ap.add_argument("--zip", type=Path, nargs="+", help="load these already-downloaded BTS zip files instead")
    ap.add_argument("--airport", default="CLT")
    ap.add_argument("--append", action="store_true", help="add to the existing database instead of rebuilding it")
    args = ap.parse_args()

    DB_PATH.parent.mkdir(parents=True, exist_ok=True)
    con = sqlite3.connect(DB_PATH)
    has_tables = con.execute("SELECT 1 FROM sqlite_master WHERE name='flights'").fetchone()
    if not args.append or not has_tables:
        con.executescript((ROOT / "sql" / "schema.sql").read_text(encoding="utf-8"))

    files = args.zip or []
    if not files:
        for m in args.months:
            try:
                files.append(download(args.year, m))
            except OSError as err:
                print(f"\n  ! couldn't download {args.year}-{m:02d}: {err}")
    if not files:
        sys.exit("Nothing to load. BTS publishes each month about 2-3 months later, so try an earlier month.")

    total = 0
    for f in files:
        n = load(con, rows_from_zip(f), args.airport.upper())
        print(f"  loaded {n:,} {args.airport.upper()} flights from {f.name}")
        total += n
    count = con.execute("SELECT COUNT(*) FROM flights").fetchone()[0]
    print(f"\nDone: {total:,} flights added, {count:,} in {DB_PATH.relative_to(ROOT)}")
    print("Next: python run_queries.py")


if __name__ == "__main__":
    main()
