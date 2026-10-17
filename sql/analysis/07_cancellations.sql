-- Why were flights cancelled, by airline?
SELECT
    f.airline_name                                           AS airline,
    c.reason                                                 AS reason,
    COUNT(*)                                                 AS cancellations,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY f.airline_name), 1) AS pct_of_airline
FROM v_flights f
JOIN cancellation_codes c ON c.code = f.cancellation_code
WHERE f.cancelled = 1
GROUP BY f.airline_name, c.reason
HAVING COUNT(*) >= 5
ORDER BY f.airline_name, cancellations DESC;
