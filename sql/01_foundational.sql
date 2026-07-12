-- Q1: Which team has won the most matches overall?
SELECT winner, COUNT(*) AS total_wins
FROM matches
WHERE winner IS NOT NULL
GROUP BY winner
ORDER BY total_wins DESC;

-- Q2: Does winning the toss actually help you win the match?
SELECT 
    CASE WHEN toss_winner = winner THEN 'Won Toss & Match' ELSE 'Won Toss, Lost Match' END AS outcome,
    COUNT(*) AS total
FROM matches
WHERE winner IS NOT NULL
GROUP BY outcome;

-- Q3: Top 10 highest individual run-scorers overall
SELECT batsman, SUM(batsman_runs) AS total_runs
FROM deliveries
GROUP BY batsman
ORDER BY total_runs DESC
LIMIT 10;

-- Q4: Most economical bowlers (minimum 200 balls bowled)
SELECT 
    bowler,
    SUM(total_runs - COALESCE(bye_runs,0) - COALESCE(legbye_runs,0)) AS runs_conceded,
    COUNT(*) AS balls_bowled,
    ROUND(SUM(total_runs - COALESCE(bye_runs,0) - COALESCE(legbye_runs,0)) / (COUNT(*)/6), 2) AS economy_rate
FROM deliveries
GROUP BY bowler
HAVING balls_bowled >= 200
ORDER BY economy_rate ASC
LIMIT 10;

-- Q5: Matches played per season
SELECT season, COUNT(*) AS matches_played
FROM matches
GROUP BY season
ORDER BY season;


