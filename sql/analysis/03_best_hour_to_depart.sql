-- When should you leave CLT? Delays build up through the day as late aircraft cascade.
SELECT
    printf('%02d:00', sched_dep_hour)                        AS sched_departure,
    COUNT(*)                                                 AS flights,
    ROUND(AVG(dep_delay_min), 1)                             AS avg_dep_delay_min,
    ROUND(100.0 * AVG(CASE WHEN dep_delay_min >= 15 THEN 1.0 ELSE 0 END), 1) AS pct_delayed_15plus
FROM v_flights
WHERE direction = 'departure' AND cancelled = 0
GROUP BY sched_dep_hour
HAVING COUNT(*) >= 50
ORDER BY sched_dep_hour;
