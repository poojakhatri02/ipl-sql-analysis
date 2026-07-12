-- Q17: "Most Valuable Death-Over Finisher" Composite Metric
-- Methodology: Finisher Score = (Strike Rate x 50%) + (Not-Out % x 30%) + (Boundary % x 20%)
-- Strike Rate (50%)  -- raw scoring speed, most important factor in death overs
-- Not-Out % (30%)    -- how often the batsman survives to close the innings
-- Boundary % (20%)   -- explosiveness; supporting signal

WITH death_balls AS (
    SELECT match_id, inning, batsman, batsman_runs, player_dismissed
    FROM deliveries
    WHERE over_number >= 17
),
batting_stats AS (
    SELECT batsman, SUM(batsman_runs) AS runs, COUNT(*) AS balls_faced,
        SUM(CASE WHEN batsman_runs = 4 THEN 1 ELSE 0 END) AS fours,
        SUM(CASE WHEN batsman_runs = 6 THEN 1 ELSE 0 END) AS sixes
    FROM death_balls
    GROUP BY batsman
),
innings_played AS (
    SELECT batsman, COUNT(DISTINCT match_id, inning) AS innings
    FROM death_balls
    GROUP BY batsman
),
dismissals AS (
    SELECT player_dismissed AS batsman, COUNT(*) AS dismissals
    FROM death_balls
    WHERE player_dismissed IS NOT NULL AND player_dismissed != ''
    GROUP BY player_dismissed
)
SELECT 
    bs.batsman, bs.runs, bs.balls_faced,
    ROUND(bs.runs * 100.0 / bs.balls_faced, 2) AS strike_rate,
    ROUND((1 - COALESCE(d.dismissals, 0) / ip.innings) * 100, 2) AS not_out_pct,
    ROUND((bs.fours + bs.sixes) * 100.0 / bs.balls_faced, 2) AS boundary_pct,
    ROUND(
        (bs.runs * 100.0 / bs.balls_faced) * 0.5 +
        ((1 - COALESCE(d.dismissals, 0) / ip.innings) * 100) * 0.3 +
        ((bs.fours + bs.sixes) * 100.0 / bs.balls_faced) * 0.2
    , 2) AS finisher_score
FROM batting_stats bs
JOIN innings_played ip ON bs.batsman = ip.batsman
LEFT JOIN dismissals d ON bs.batsman = d.batsman
WHERE bs.balls_faced >= 60
ORDER BY finisher_score DESC
LIMIT 15;
