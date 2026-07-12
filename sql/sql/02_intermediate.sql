-- Q6: Rank teams by wins within each season
SELECT 
    season, winner, COUNT(*) AS wins,
    RANK() OVER (PARTITION BY season ORDER BY COUNT(*) DESC) AS season_rank
FROM matches
WHERE winner IS NOT NULL
GROUP BY season, winner
ORDER BY season, season_rank;

-- Q7: Running total of runs per over (V Kohli, 2016 season)
SELECT 
    over_number,
    SUM(batsman_runs) AS runs_in_over,
    SUM(SUM(batsman_runs)) OVER (ORDER BY over_number) AS running_total
FROM deliveries d
JOIN matches m ON d.match_id = m.id
WHERE batsman = 'V Kohli' AND m.season = 2016
GROUP BY over_number
ORDER BY over_number;

-- Q8: Best "finishers" — highest strike rate in death overs (min. 60 balls)
SELECT 
    batsman, SUM(batsman_runs) AS runs_in_death_overs, COUNT(*) AS balls_faced,
    ROUND(SUM(batsman_runs) * 100.0 / COUNT(*), 2) AS strike_rate
FROM deliveries
WHERE over_number >= 17
GROUP BY batsman
HAVING balls_faced >= 60
ORDER BY strike_rate DESC
LIMIT 10;

-- Q9: Year-over-year trend in average first-innings score
SELECT m.season, ROUND(AVG(first_innings_runs), 1) AS avg_first_innings_score
FROM (
    SELECT match_id, SUM(total_runs) AS first_innings_runs
    FROM deliveries WHERE inning = 1 GROUP BY match_id
) AS innings_totals
JOIN matches m ON innings_totals.match_id = m.id
GROUP BY m.season
ORDER BY m.season;

-- Q10: Top wicket-taker per season
SELECT * FROM (
    SELECT m.season, d.bowler, COUNT(*) AS wickets,
        RANK() OVER (PARTITION BY m.season ORDER BY COUNT(*) DESC) AS season_rank
    FROM deliveries d
    JOIN matches m ON d.match_id = m.id
    WHERE d.player_dismissed IS NOT NULL AND d.player_dismissed != ''
        AND d.dismissal_kind NOT IN ('run out', 'retired hurt', 'obstructing the field')
    GROUP BY m.season, d.bowler
) ranked
WHERE season_rank = 1
ORDER BY season;
