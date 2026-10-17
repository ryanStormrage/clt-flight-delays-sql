-- What causes the delays? Share of all delay minutes by cause (flights arriving 15+ min late).
WITH totals AS (
    SELECT
        SUM(carrier_delay)       AS carrier,
        SUM(weather_delay)       AS weather,
        SUM(nas_delay)           AS air_system,
        SUM(security_delay)      AS security,
        SUM(late_aircraft_delay) AS late_aircraft
    FROM flights
    WHERE arr_delay_min >= 15
)
SELECT 'Late-arriving aircraft' AS cause, ROUND(late_aircraft, 0) AS minutes,
       ROUND(100.0 * late_aircraft / (carrier + weather + air_system + security + late_aircraft), 1) AS pct FROM totals
UNION ALL SELECT 'Airline (crew, maintenance…)', ROUND(carrier, 0),
       ROUND(100.0 * carrier / (carrier + weather + air_system + security + late_aircraft), 1) FROM totals
UNION ALL SELECT 'National Air System (ATC, volume)', ROUND(air_system, 0),
       ROUND(100.0 * air_system / (carrier + weather + air_system + security + late_aircraft), 1) FROM totals
UNION ALL SELECT 'Extreme weather', ROUND(weather, 0),
       ROUND(100.0 * weather / (carrier + weather + air_system + security + late_aircraft), 1) FROM totals
UNION ALL SELECT 'Security', ROUND(security, 0),
       ROUND(100.0 * security / (carrier + weather + air_system + security + late_aircraft), 1) FROM totals
ORDER BY minutes DESC;
