-- The 10 worst days at CLT, with a 7-day rolling on-time rate for context (window functions).
WITH daily AS (
    SELECT flight_date,
           COUNT(*)                         AS flights,
           100.0 * AVG(on_time)             AS on_time_pct,
           100.0 * AVG(cancelled)           AS cancelled_pct
    FROM v_flights
    GROUP BY flight_date
),
rolled AS (
    SELECT *,
           AVG(on_time_pct) OVER (ORDER BY flight_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS rolling_7d
    FROM daily
)
SELECT flight_date, flights,
       ROUND(on_time_pct, 1)   AS on_time_pct,
       ROUND(cancelled_pct, 1) AS cancelled_pct,
       ROUND(rolling_7d, 1)    AS rolling_7d_on_time
FROM rolled
ORDER BY on_time_pct ASC
LIMIT 10;
