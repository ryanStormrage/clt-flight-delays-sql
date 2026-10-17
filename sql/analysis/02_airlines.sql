-- Which airlines are most reliable at CLT? (min. 200 flights)
SELECT
    airline_name                                             AS airline,
    COUNT(*)                                                 AS flights,
    ROUND(100.0 * AVG(on_time), 1)                           AS on_time_pct,
    ROUND(AVG(CASE WHEN arr_delay_min > 0 THEN arr_delay_min END), 1) AS avg_delay_when_late,
    ROUND(100.0 * AVG(cancelled), 2)                         AS cancelled_pct
FROM v_flights
GROUP BY airline_name
HAVING COUNT(*) >= 200
ORDER BY on_time_pct DESC;
