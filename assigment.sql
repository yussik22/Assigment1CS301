WITH repair_by_bike AS (
    SELECT
        cycle_key,
        COUNT(*) AS repair_count,
        SUM(parts_cost_uah + labor_cost_uah) AS repair_cost
    FROM repair_event_journal
    WHERE closed_flag = 'yes'
    GROUP BY cycle_key
),
main_result AS (
    SELECT
        d.city_side,
        s.tariff_name,
        c.frame_family,
        COUNT(r.ride_key) AS total_rides,
        ROUND(SUM(r.fare_uah), 2) AS total_income,
        ROUND(AVG(r.minutes_used), 1) AS avg_minutes,
        COUNT(DISTINCT r.cycle_key) AS used_bikes,
        SUM(CASE
            WHEN r.finish_code <> 'completed' THEN 1
            ELSE 0
        END) AS problem_rides,
        ROUND(SUM(IFNULL(rb.repair_cost, 0)), 2) AS repair_cost
    FROM ride_activity_log r
    JOIN subscriber_registry s
        ON r.subscriber_key = s.subscriber_key
    JOIN cycle_inventory c
        ON r.cycle_key = c.cycle_key
    JOIN dock_sector_map d
        ON r.start_sector_key = d.sector_key
    LEFT JOIN repair_by_bike rb
        ON c.cycle_key = rb.cycle_key
    WHERE r.started_at >= '2025-06-01'
      AND s.account_state = 'active'
      AND c.asset_state <> 'retired'
      AND d.risk_band IN ('medium', 'elevated')
    GROUP BY
        d.city_side,
        s.tariff_name,
        c.frame_family
)

SELECT
    'detailed result' AS row_type,
    city_side,
    tariff_name,
    frame_family,
    total_rides,
    total_income,
    avg_minutes,
    used_bikes,
    problem_rides,
    repair_cost
FROM main_result
WHERE total_rides >= 3

UNION ALL

SELECT
    'summary by tariff' AS row_type,
    'all city sides' AS city_side,
    tariff_name,
    'all bike types' AS frame_family,
    SUM(total_rides) AS total_rides,
    ROUND(SUM(total_income), 2) AS total_income,
    ROUND(AVG(avg_minutes), 1) AS avg_minutes,
    SUM(used_bikes) AS used_bikes,
    SUM(problem_rides) AS problem_rides,
    ROUND(SUM(repair_cost), 2) AS repair_cost
FROM main_result
GROUP BY tariff_name

ORDER BY total_income DESC, total_rides DESC;
