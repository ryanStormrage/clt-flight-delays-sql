-- Best and worst days of the week to fly through CLT.
SELECT
    CASE day_of_week WHEN 1 THEN 'Mon' WHEN 2 THEN 'Tue' WHEN 3 THEN 'Wed' WHEN 4 THEN 'Thu'
                     WHEN 5 THEN 'Fri' WHEN 6 THEN 'Sat' ELSE 'Sun' END AS day,
    COUNT(*)                                                 AS flights,
    ROUND(100.0 * AVG(on_time), 1)                           AS on_time_pct,
    ROUND(AVG(CASE WHEN cancelled = 0 THEN arr_delay_min END), 1) AS avg_arr_delay_min
FROM v_flights
GROUP BY day_of_week
ORDER BY day_of_week;
