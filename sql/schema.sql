-- CLT flight delays: database schema (SQLite)
-- One row per scheduled flight that departed from or arrived at Charlotte (CLT).

DROP TABLE IF EXISTS flights;
DROP TABLE IF EXISTS airlines;
DROP TABLE IF EXISTS airports;
DROP TABLE IF EXISTS cancellation_codes;

CREATE TABLE airlines (
    code  TEXT PRIMARY KEY,         -- BTS reporting carrier code, e.g. 'AA'
    name  TEXT NOT NULL
);

CREATE TABLE airports (
    code   TEXT PRIMARY KEY,        -- IATA code, e.g. 'LGA'
    city   TEXT,                    -- 'New York, NY'
    state  TEXT
);

CREATE TABLE cancellation_codes (
    code    TEXT PRIMARY KEY,
    reason  TEXT NOT NULL
);

INSERT INTO cancellation_codes VALUES
    ('A', 'Carrier'), ('B', 'Weather'), ('C', 'National Air System'), ('D', 'Security');

CREATE TABLE flights (
    id                 INTEGER PRIMARY KEY,
    flight_date        TEXT    NOT NULL,           -- YYYY-MM-DD
    day_of_week        INTEGER NOT NULL,           -- 1 = Monday … 7 = Sunday
    airline            TEXT    NOT NULL REFERENCES airlines(code),
    flight_number      TEXT,
    tail_number        TEXT,
    origin             TEXT    NOT NULL REFERENCES airports(code),
    dest               TEXT    NOT NULL REFERENCES airports(code),
    direction          TEXT    NOT NULL CHECK (direction IN ('departure', 'arrival')),  -- relative to CLT
    sched_dep_hour     INTEGER,                    -- 0-23, local time
    sched_arr_hour     INTEGER,
    dep_delay_min      REAL,                       -- negative = left early
    arr_delay_min      REAL,
    taxi_out_min       REAL,
    cancelled          INTEGER NOT NULL DEFAULT 0,
    cancellation_code  TEXT REFERENCES cancellation_codes(code),
    diverted           INTEGER NOT NULL DEFAULT 0,
    distance_miles     REAL,
    -- minutes of delay attributed to each cause (only filled when arrival delay >= 15)
    carrier_delay      REAL,
    weather_delay      REAL,
    nas_delay          REAL,
    security_delay     REAL,
    late_aircraft_delay REAL
);

CREATE INDEX ix_flights_airline   ON flights(airline);
CREATE INDEX ix_flights_date      ON flights(flight_date);
CREATE INDEX ix_flights_route     ON flights(origin, dest);
CREATE INDEX ix_flights_direction ON flights(direction);

-- Handy view: a flight counts as "on time" if it arrived < 15 minutes late (the DOT definition).
DROP VIEW IF EXISTS v_flights;
CREATE VIEW v_flights AS
SELECT f.*,
       a.name AS airline_name,
       CASE WHEN f.cancelled = 0 AND f.diverted = 0 AND f.arr_delay_min < 15 THEN 1 ELSE 0 END AS on_time,
       CASE WHEN f.direction = 'departure' THEN f.dest ELSE f.origin END                 AS other_airport
FROM flights f
JOIN airlines a ON a.code = f.airline;
