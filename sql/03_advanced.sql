-- Q11: Bowler vs Batsman matchup — who dismisses whom the most
SELECT bowler, player_dismissed AS batsman, COUNT(*) AS dismissals
FROM deliveries
WHERE player_dismissed IS NOT NULL AND player_dismissed != ''
    AND dismissal_kind NOT IN ('run out', 'retired hurt', 'obstructing the field')
GROUP BY bowler, player_dismissed
HAVING dismissals >= 4
ORDER BY dismissals DESC
LIMIT 15;

-- Q12: Chasing vs Defending win rate by team
SELECT winner,
    SUM(CASE WHEN win_by_wickets > 0 THEN 1 ELSE 0 END) AS wins_chasing,
    SUM(CASE WHEN win_by_runs > 0 THEN 1 ELSE 0 END) AS wins_defending
FROM matches
WHERE winner IS NOT NULL AND winner != ''
GROUP BY winner
ORDER BY (wins_chasing + wins_defending) DESC
LIMIT 10;

-- Q13: Venue bias — scoring and chasing/defending tendencies
SELECT m.venue, COUNT(DISTINCT m.id) AS matches_played,
    ROUND(AVG(innings_totals.first_innings_runs), 1) AS avg_first_innings_score,
    SUM(CASE WHEN m.win_by_wickets > 0 THEN 1 ELSE 0 END) AS chasing_wins,
    SUM(CASE WHEN m.win_by_runs > 0 THEN 1 ELSE 0 END) AS defending_wins
FROM matches m
JOIN (
    SELECT match_id, SUM(total_runs) AS first_innings_runs
    FROM deliveries WHERE inning = 1 GROUP BY match_id
) AS innings_totals ON innings_totals.match_id = m.id
WHERE m.winner IS NOT NULL AND m.winner != ''
GROUP BY m.venue
HAVING matches_played >= 20
ORDER BY avg_first_innings_score DESC;

-- Q14: Toss decision trend over seasons
SELECT season, toss_decision, COUNT(*) AS total
FROM matches
GROUP BY season, toss_decision
ORDER BY season, toss_decision;

-- Q15: Death-overs specialist bowlers (economy in overs 17-20)
SELECT bowler, SUM(total_runs) AS runs_conceded, COUNT(*) AS balls_bowled,
    ROUND(SUM(total_runs) / (COUNT(*)/6), 2) AS death_over_economy
FROM deliveries
WHERE over_number >= 17
GROUP BY bowler
HAVING balls_bowled >= 60
ORDER BY death_over_economy ASC
LIMIT 10;

-- Q16: Toss Myth-Busting Summary
-- Synthesized from Q2, Q12, and Q14 findings:
-- 1. "Winning the toss wins you the match" -> Busted (mostly). Toss winners won only 52% of matches.
-- 2. "Chasing is always easier" -> Team-dependent. MI and CSK actually win more often defending.
-- 3. "Teams have always preferred to field first" -> Busted for early seasons, true for
