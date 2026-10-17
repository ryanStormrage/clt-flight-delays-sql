-- Least reliable routes out of CLT (min. 100 departures).
SELECT
    f.dest                                                   AS dest,
    ap.city                                                  AS city,
    COUNT(*)                                                 AS flights,
    ROUND(100.0 * AVG(f.on_time), 1)                         AS on_time_pct,
    ROUND(AVG(CASE WHEN f.cancelled = 0 THEN f.arr_delay_min END), 1) AS avg_arr_delay_min,
    ROUND(100.0 * AVG(f.cancelled), 2)                       AS cancelled_pct
FROM v_flights f
JOIN airports ap ON ap.code = f.dest
WHERE f.direction = 'departure'
GROUP BY f.dest
HAVING COUNT(*) >= 100
ORDER BY on_time_pct ASC
LIMIT 10;
