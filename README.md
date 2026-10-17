# CLT Flight Delays in SQL

A SQL analysis of every flight in and out of **Charlotte Douglas International (CLT)**, built from the U.S. Department of
Transportation's public on-time performance data.

It asks practical questions in plain SQL:

| # | question | SQL used |
|---|---|---|
| 01 | How on-time is CLT overall? | aggregates, `CASE` |
| 02 | Which airlines are most reliable here? | `GROUP BY … HAVING` |
| 03 | What's the best hour to depart? | conditional averages |
| 04 | Best and worst day of the week? | `CASE` mapping |
| 05 | What actually causes the delays? | CTE + `UNION ALL` |
| 06 | Least reliable routes out of CLT | joins, `LIMIT` |
| 07 | Why do flights get cancelled, by airline? | window `SUM() OVER (PARTITION BY)` |
| 08 | The 10 worst days, with a 7-day rolling average | window frames `ROWS BETWEEN` |
| 09 | Most reliable airline to each top destination | `RANK() OVER` + CTEs |
| 10 | How much of CLT is American Airlines? | scalar subquery |

The results are written to **[`results/REPORT.md`](results/REPORT.md)**.

**Stack:** SQLite, Python 3.10+ (standard library only) for loading data

## Data source

[Bureau of Transportation Statistics: Reporting Carrier On-Time Performance (1987–present)](https://www.transtats.bts.gov/Tables.asp?QO_VQ=EFD).
This U.S. government open data is in the public domain. Every domestic flight by a large U.S. airline is reported
with its scheduled and actual times, delay minutes broken down by cause, cancellations and diversions.
BTS publishes each month about 2–3 months after it ends.

## Run it

```bash
python load_data.py                 # downloads Jun–Aug 2025 (~30 MB each) and keeps only CLT flights
python run_queries.py               # runs every query and writes results/REPORT.md
```

More options:

```bash
python load_data.py --year 2025 --months 1 2 3 4 5 6 7 8 9 10 11 12   # a full year
python load_data.py --airport ATL                                     # analyze a different airport
python run_queries.py 02 09                                            # run just some queries
python run_queries.py --sql "SELECT dest, COUNT(*) FROM flights GROUP BY dest ORDER BY 2 DESC LIMIT 5"
```

You can also open `data/clt_flights.db` in [DB Browser for SQLite](https://sqlitebrowser.org/) or the VS Code
*SQLite Viewer* extension and run queries by hand.

## Schema

```
airlines (code PK, name)
airports (code PK, city, state)
cancellation_codes (code PK, reason)
flights (id PK, flight_date, day_of_week, airline FK, flight_number, tail_number,
         origin FK, dest FK, direction ['departure'|'arrival'],
         sched_dep_hour, sched_arr_hour, dep_delay_min, arr_delay_min, taxi_out_min,
         cancelled, cancellation_code FK, diverted, distance_miles,
         carrier_delay, weather_delay, nas_delay, security_delay, late_aircraft_delay)

v_flights  = flights + airline_name + on_time flag (arrived < 15 min late) + other_airport
```

Full DDL: [`sql/schema.sql`](sql/schema.sql)

## Related

This project is the data side of [clt-flight-deals](https://github.com/ryanstormrage/clt-flight-deals): a cheap fare
isn't much of a deal if that airline is late half the time on that route.
