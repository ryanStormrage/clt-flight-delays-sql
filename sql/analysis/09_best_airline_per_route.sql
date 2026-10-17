-- For each of CLT's 10 busiest destinations, which airline gets you there most reliably?
WITH busiest AS (
    SELECT dest FROM v_flights WHERE direction = 'departure'
    GROUP BY dest ORDER BY COUNT(*) DESC LIMIT 10
),
ranked AS (
    SELECT f.dest, f.airline_name,
           COUNT(*)                                   AS flights,
           100.0 * AVG(f.on_time)                     AS on_time_pct,
           RANK() OVER (PARTITION BY f.dest ORDER BY AVG(f.on_time) DESC) AS rnk
    FROM v_flights f
    JOIN busiest b ON b.dest = f.dest
    WHERE f.direction = 'departure'
    GROUP BY f.dest, f.airline_name
    HAVING COUNT(*) >= 30
)
SELECT dest, airline_name AS best_airline, flights, ROUND(on_time_pct, 1) AS on_time_pct
FROM ranked
WHERE rnk = 1
ORDER BY dest;
