-- CLT is one of American Airlines' biggest hubs. How much of the airport is American (mainline + regionals)?
-- Approximate: Republic (YX) and Envoy-style regionals can also fly for other airlines.
SELECT
    CASE WHEN airline IN ('AA', 'OH', 'YX', 'MQ', 'PT') THEN 'American + American Eagle'
         ELSE airline_name END                               AS carrier_group,
    COUNT(*)                                                 AS flights,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM flights), 1) AS share_pct
FROM v_flights
GROUP BY carrier_group
ORDER BY flights DESC;
