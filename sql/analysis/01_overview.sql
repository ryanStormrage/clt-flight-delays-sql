-- How did CLT do overall?
-- On-time = arrived less than 15 minutes late (U.S. DOT definition).
SELECT
    MIN(flight_date)                                         AS first_day,
    MAX(flight_date)                                         AS last_day,
    COUNT(*)                                                 AS flights,
    ROUND(100.0 * AVG(on_time), 1)                           AS on_time_pct,
    ROUND(100.0 * AVG(cancelled), 2)                         AS cancelled_pct,
    ROUND(AVG(CASE WHEN cancelled = 0 THEN dep_delay_min END), 1) AS avg_dep_delay_min,
    ROUND(AVG(CASE WHEN cancelled = 0 THEN taxi_out_min END), 1)  AS avg_taxi_out_min
FROM v_flights;
