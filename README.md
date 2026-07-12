# 🏏 IPL Cricket Match Analysis — SQL Portfolio Project

An end-to-end SQL analysis of Indian Premier League (IPL) match and ball-by-ball data (2008–2019), built to demonstrate SQL skills ranging from foundational aggregation to advanced window functions, CTEs, and composite performance metrics.

**Tools:** MySQL 8.0, MySQL Workbench
**Dataset:** IPL Complete Dataset (Kaggle) — `matches.csv` (756 matches, 2008–2019) and `deliveries.csv` (150,460 ball-by-ball records, 2008–2017)

---

## 📌 Headline Finding

**AB de Villiers is the most valuable death-over finisher in IPL history (2008–2017)** — a composite score combining strike rate, not-out percentage, and boundary percentage ranks him #1 overall, ahead of every other batsman in the dataset. See [Q17](#q17-centerpiece-most-valuable-death-over-finisher-composite-metric) for the full breakdown and methodology.

Other standout findings:
- Winning the toss barely matters — toss winners won only **52%** of matches ([Q2](#q2-does-winning-the-toss-actually-help-you-win-the-match))
- The "always field first" strategy is a *recent* trend, not a constant truth — it rose from ~35% of toss decisions in 2010 to **83%+ by 2018–19** ([Q14](#q14-toss-decision-trend-over-seasons))
- The two most successful franchises (Mumbai Indians, Chennai Super Kings) actually win *more often defending* totals than chasing — contrary to the common T20 assumption ([Q12](#q12-chasing-vs-defending-win-rate-by-team))

---

## 🗂️ Schema

**`matches`** — one row per match (756 rows, 2008–2019)

| Column | Type | Description |
|---|---|---|
| id | INT (PK) | Match ID |
| season | INT | Year |
| city | VARCHAR | Host city |
| match_date | DATE | Date played |
| team1, team2 | VARCHAR | Competing teams |
| toss_winner, toss_decision | VARCHAR | Toss outcome |
| winner, win_by_runs, win_by_wickets | — | Result |
| venue | VARCHAR | Stadium |

**`deliveries`** — one row per ball bowled (150,460 rows, 2008–2017)

| Column | Type | Description |
|---|---|---|
| match_id | INT (FK) | Links to matches.id |
| inning, over_number, ball | INT | Ball location |
| batsman, bowler, non_striker | VARCHAR | Players involved |
| batsman_runs, extra_runs, total_runs | INT | Runs scored |
| player_dismissed, dismissal_kind | VARCHAR | Wicket info |

### Data Cleaning & Limitations
- **Ball-by-ball data scope:** `deliveries` covers seasons 2008–2017 only. `matches` covers 2008–2019. Analyses using `deliveries` (batting/bowling stats, strike rates) are scoped to 2008–2017; analyses using only `matches` (team wins, toss impact) cover the full 2008–2019 range. Verified by confirming zero delivery records exist for 2018–2019.
- **Missing winners:** ~7 matches across the dataset have no recorded winner (blank field), likely abandoned or no-result games — excluded from team-level win-count analysis.
- **Column renaming:** Source CSV columns `date` and `over` were renamed to `match_date` and `over_number` to avoid conflicts with SQL reserved words.

---

## Foundational Analysis

### Q1: Which team has won the most matches overall?
```sql
SELECT winner, COUNT(*) AS total_wins
FROM matches
WHERE winner IS NOT NULL
GROUP BY winner
ORDER BY total_wins DESC;
```
| Team | Total Wins |
|---|---|
| Mumbai Indians | 109 |
| Chennai Super Kings | 100 |
| Kolkata Knight Riders | 92 |
| Royal Challengers Bangalore | 84 |
| Kings XI Punjab | 82 |
| Rajasthan Royals | 75 |
| Delhi Daredevils | 67 |
| Sunrisers Hyderabad | 58 |

**Finding:** Mumbai Indians lead all-time wins, narrowly ahead of Chennai Super Kings — consistent with their reputation as the two most successful IPL franchises.

---

### Q2: Does winning the toss actually help you win the match?
```sql
SELECT 
    CASE WHEN toss_winner = winner THEN 'Won Toss & Match' ELSE 'Won Toss, Lost Match' END AS outcome,
    COUNT(*) AS total
FROM matches
WHERE winner IS NOT NULL
GROUP BY outcome;
```
| Outcome | Total Matches |
|---|---|
| Won Toss & Match | 393 |
| Won Toss, Lost Match | 363 |

**Finding:** Out of 756 matches, the toss-winning team won only **52%** of the time — barely better than a coin flip. The toss gives a slight edge at best, not the decisive advantage many fans assume.

---

### Q3: Top 10 highest individual run-scorers overall
```sql
SELECT batsman, SUM(batsman_runs) AS total_runs
FROM deliveries
GROUP BY batsman
ORDER BY total_runs DESC
LIMIT 10;
```
| Rank | Batsman | Total Runs |
|---|---|---|
| 1 | SK Raina | 4548 |
| 2 | V Kohli | 4423 |
| 3 | RG Sharma | 4207 |
| 4 | G Gambhir | 4132 |
| 5 | DA Warner | 4014 |
| 6 | RV Uthappa | 3778 |
| 7 | CH Gayle | 3651 |
| 8 | S Dhawan | 3561 |
| 9 | MS Dhoni | 3560 |
| 10 | AB de Villiers | 3486 |

**Finding:** SK Raina tops the all-time run charts, narrowly ahead of Virat Kohli — both known for consistency across a decade-plus of IPL seasons.

---

### Q4: Most economical bowlers (minimum 200 balls bowled)
```sql
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
```
| Rank | Bowler | Runs Conceded | Balls Bowled | Economy Rate |
|---|---|---|---|---|
| 1 | Sohail Tanvir | 266 | 265 | 6.02 |
| 2 | A Chandila | 242 | 234 | 6.21 |
| 3 | SP Narine | 2042 | 1956 | 6.26 |
| 4 | R Ashwin | 2499 | 2359 | 6.36 |
| 5 | SM Pollock | 301 | 280 | 6.45 |

**Finding:** Spinners dominate this list (Narine, Ashwin, Kumble, Muralitharan) — a well-known T20 pattern where quality spin is harder to hit than pace on Indian pitches. Note: Sohail Tanvir and A Chandila top it with much smaller sample sizes (~250 balls) than Malinga's ~2,700, making their economy less statistically reliable.

---

### Q5: Matches played per season
```sql
SELECT season, COUNT(*) AS matches_played
FROM matches
GROUP BY season
ORDER BY season;
```
| Season | Matches | Season | Matches |
|---|---|---|---|
| 2008 | 58 | 2014 | 60 |
| 2009 | 57 | 2015 | 59 |
| 2010 | 60 | 2016 | 60 |
| 2011 | 73 | 2017 | 59 |
| 2012 | 74 | 2018 | 60 |
| 2013 | 76 | 2019 | 60 |

**Finding:** IPL settled into a stable ~60-match season format after experimentation in 2011–2013 (73–76 matches, reflecting more franchises during those years).

---

## Intermediate Analysis

### Q6: Rank teams by wins within each season
```sql
SELECT 
    season, winner, COUNT(*) AS wins,
    RANK() OVER (PARTITION BY season ORDER BY COUNT(*) DESC) AS season_rank
FROM matches
WHERE winner IS NOT NULL
GROUP BY season, winner
ORDER BY season, season_rank;
```
**Top team per season:**
| Season | Top Team | Wins |
|---|---|---|
| 2008 | Rajasthan Royals | 13 |
| 2010 | Mumbai Indians | 11 |
| 2013 | Mumbai Indians | 13 |
| 2017 | Mumbai Indians | 12 |
| 2019 | Mumbai Indians | 11 |

**Finding:** Mumbai Indians topped the regular-season win count in 4 of 12 seasons — more than any other franchise — reinforcing their consistent dominance beyond just the highest all-time total.

---

### Q7: Running total of runs per over (V Kohli, 2016 season)
```sql
SELECT 
    over_number,
    SUM(batsman_runs) AS runs_in_over,
    SUM(SUM(batsman_runs)) OVER (ORDER BY over_number) AS running_total
FROM deliveries d
JOIN matches m ON d.match_id = m.id
WHERE batsman = 'V Kohli' AND m.season = 2016
GROUP BY over_number
ORDER BY over_number;
```
| Over | Runs in Over | Running Total |
|---|---|---|
| 1 | 42 | 42 |
| 10 | 70 | 494 |
| 19 | 74 | 930 |
| 20 | 43 | 973 |

**Finding:** Kohli's 2016 season (his career-best) shows strong scoring in both the powerplay (overs 1–6: 278 runs) and death overs (overs 18–20: 177 runs), reflecting his reputation as one of the most complete batsmen of that era.

---

### Q8: Best "finishers" — highest strike rate in death overs (min. 60 balls)
```sql
SELECT 
    batsman, SUM(batsman_runs) AS runs_in_death_overs, COUNT(*) AS balls_faced,
    ROUND(SUM(batsman_runs) * 100.0 / COUNT(*), 2) AS strike_rate
FROM deliveries
WHERE over_number >= 17
GROUP BY batsman
HAVING balls_faced >= 60
ORDER BY strike_rate DESC
LIMIT 10;
```
| Rank | Batsman | Runs | Balls | Strike Rate |
|---|---|---|---|---|
| 1 | AB de Villiers | 905 | 409 | 221.27 |
| 2 | CH Gayle | 277 | 133 | 208.27 |
| 5 | V Kohli | 724 | 374 | 193.58 |
| 7 | RG Sharma | 1040 | 539 | 192.95 |

**Finding:** AB de Villiers is the clear standout death-overs finisher (221 strike rate) across a large, reliable sample (409 balls). RG Sharma has the highest total *volume* (1040 runs) despite a lower strike rate — an important distinction between "most prolific" and "most explosive," which motivated the composite metric in Q17.

---

### Q9: Year-over-year trend in average first-innings score
```sql
SELECT m.season, ROUND(AVG(first_innings_runs), 1) AS avg_first_innings_score
FROM (
    SELECT match_id, SUM(total_runs) AS first_innings_runs
    FROM deliveries WHERE inning = 1 GROUP BY match_id
) AS innings_totals
JOIN matches m ON innings_totals.match_id = m.id
GROUP BY m.season
ORDER BY m.season;
```
| Season | Avg 1st-Innings Score |
|---|---|
| 2008 | 161.0 |
| 2012 | 157.5 |
| 2015 | 166.3 |
| 2017 | 165.8 |

**Finding:** First-innings scores stayed fairly consistent (150–166 range) across a decade with no dramatic trend — busting the assumption that IPL scores climbed steadily as bats/grounds evolved. *(Scoped to 2008–2017 per data limitations.)*

---

### Q10: Top wicket-taker per season
```sql
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
```
| Season | Top Wicket-Taker | Wickets |
|---|---|---|
| 2013 | DJ Bravo | 32 |
| 2015 | DJ Bravo | 26 |
| 2016 | B Kumar | 23 |
| 2017 | B Kumar | 26 |

**Finding:** DJ Bravo and B Kumar are the only bowlers to top the wicket charts twice, showing sustained excellence across multiple seasons.

---

## Advanced Analysis

### Q11: Bowler vs Batsman matchup — who dismisses whom the most
```sql
SELECT bowler, player_dismissed AS batsman, COUNT(*) AS dismissals
FROM deliveries
WHERE player_dismissed IS NOT NULL AND player_dismissed != ''
    AND dismissal_kind NOT IN ('run out', 'retired hurt', 'obstructing the field')
GROUP BY bowler, player_dismissed
HAVING dismissals >= 4
ORDER BY dismissals DESC
LIMIT 15;
```
| Bowler | Batsman Dismissed | Times |
|---|---|---|
| Z Khan | MS Dhoni | 7 |
| PP Ojha | MS Dhoni | 6 |
| A Nehra | V Kohli | 6 |
| R Vinay Kumar | RG Sharma | 6 |

**Finding:** Z Khan holds MS Dhoni's "bunny" title — dismissing him 7 times, the strongest single matchup in the dataset.

---

### Q12: Chasing vs Defending win rate by team
```sql
SELECT winner,
    SUM(CASE WHEN win_by_wickets > 0 THEN 1 ELSE 0 END) AS wins_chasing,
    SUM(CASE WHEN win_by_runs > 0 THEN 1 ELSE 0 END) AS wins_defending
FROM matches
WHERE winner IS NOT NULL AND winner != ''
GROUP BY winner
ORDER BY (wins_chasing + wins_defending) DESC
LIMIT 10;
```
| Team | Wins Chasing | Wins Defending |
|---|---|---|
| Mumbai Indians | 50 | 57 |
| Chennai Super Kings | 48 | 52 |
| Kolkata Knight Riders | 56 | 36 |
| Gujarat Lions | 12 | 1 |

**Finding:** Most teams have a clear chasing-vs-defending identity. KKR and Gujarat Lions are strongly chase-dependent, while Mumbai Indians and CSK — the two most successful franchises — actually have a slight edge *defending* totals, contrary to the common "chasing is easier" assumption.

---

### Q13: Venue bias — scoring and chasing/defending tendencies
```sql
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
```
| Venue | Matches | Avg Score | Chasing Wins | Defending Wins |
|---|---|---|---|---|
| M Chinnaswamy Stadium | 64 | 167.1 | 36 | 27 |
| MA Chidambaram Stadium, Chepauk | 48 | 166.0 | 17 | 30 |
| Eden Gardens | 61 | 154.1 | 36 | 25 |

**Finding:** M Chinnaswamy Stadium (Bangalore) is the highest-scoring, most chase-friendly venue — consistent with its small boundaries. Chepauk (Chennai) shows the opposite: lower-scoring and defending-friendly, matching CSK's spin-heavy home identity.

---

### Q14: Toss decision trend over seasons
```sql
SELECT season, toss_decision, COUNT(*) AS total
FROM matches
GROUP BY season, toss_decision
ORDER BY season, toss_decision;
```
| Season | % Chose to Field |
|---|---|
| 2009 | 39% |
| 2010 | 35% |
| 2014 | 68% |
| 2016 | 82% |
| 2018 | 83% |
| 2019 | 83% |

**Finding:** A clear meta-shift — early IPL seasons favored batting first, but from 2016 onward over 80% of toss winners chose to field, reflecting the modern T20 strategic consensus (better read of the target, dew factor, data-driven decisions).

---

### Q15: Death-overs specialist bowlers (economy in overs 17–20)
```sql
SELECT bowler, SUM(total_runs) AS runs_conceded, COUNT(*) AS balls_bowled,
    ROUND(SUM(total_runs) / (COUNT(*)/6), 2) AS death_over_economy
FROM deliveries
WHERE over_number >= 17
GROUP BY bowler
HAVING balls_bowled >= 60
ORDER BY death_over_economy ASC
LIMIT 10;
```
| Bowler | Runs | Balls | Economy |
|---|---|---|---|
| SP Narine | 631 | 509 | 7.44 |
| SL Malinga | 1124 | 891 | 7.57 |
| MA Starc | 258 | 198 | 7.82 |

**Finding:** SL Malinga bowled by far the most death-over deliveries (891 balls, nearly double the next closest) while maintaining a strong 7.57 economy — confirming his reputation as arguably the greatest death-over specialist in T20 history.

---

### Q16: Toss Myth-Busting Summary
Synthesizing Q2, Q12, and Q14:

- **"Winning the toss wins you the match."** → **Busted (mostly).** Toss winners won only 52% of matches — barely better than chance.
- **"Chasing is always the easier strategy."** → **Team-dependent.** Some teams (KKR, Gujarat Lions) strongly favor chasing, but the two most successful franchises (MI, CSK) win more often *defending*.
- **"Teams have always preferred to field first."** → **Busted for early seasons, true for recent ones.** Early IPL favored batting first; by 2016+, 80%+ chose to field — a genuine strategic evolution, not a constant truth.

---

## Q17 (Centerpiece): "Most Valuable Death-Over Finisher" Composite Metric

**Methodology:** A single score combining three components, weighted by importance to death-overs finishing:

```
Finisher Score = (Strike Rate × 50%) + (Not-Out % × 30%) + (Boundary % × 20%)
```
- **Strike Rate** (50%) — raw scoring speed, the most important factor in death overs
- **Not-Out %** (30%) — how often the batsman survives to close the innings
- **Boundary %** (20%) — explosiveness; supporting signal that overlaps partially with strike rate

```sql
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
```

| Rank | Batsman | Runs | Balls | Strike Rate | Not-Out % | Boundary % | **Finisher Score** |
|---|---|---|---|---|---|---|---|
| 1 | **AB de Villiers** | 905 | 409 | 221.27 | 50.00 | 34.72 | **132.58** |
| 2 | CH Gayle | 277 | 133 | 208.27 | 52.94 | 33.08 | 126.63 |
| 3 | BB McCullum | 158 | 78 | 202.56 | 50.00 | 29.49 | 122.18 |
| 4 | SN Khan | 121 | 61 | 198.36 | 55.56 | 31.15 | 122.08 |
| 5 | DA Miller | 521 | 270 | 192.96 | 54.29 | 25.19 | 117.80 |
| 6 | CH Morris | 321 | 178 | 180.34 | 72.73 | 23.03 | 116.59 |
| 7 | DA Warner | 284 | 149 | 190.60 | 47.62 | 28.19 | 115.23 |
| 8 | JH Kallis | 303 | 159 | 190.57 | 42.86 | 28.30 | 113.80 |
| 9 | CJ Anderson | 142 | 77 | 184.42 | 54.55 | 24.68 | 113.51 |
| 10 | V Kohli | 724 | 374 | 193.58 | 36.96 | 28.07 | 113.49 |

**Finding:** AB de Villiers is the definitive "Most Valuable Death-Over Finisher" — topping every individual component (highest strike rate, tied-highest not-out rate, highest boundary %) across a large, reliable sample of 409 balls. Notably, **volume leaders don't automatically win**: RG Sharma faced the most death-over balls of anyone in the dataset (1040 runs) but ranks lower than de Villiers because his not-out percentage is comparatively low — demonstrating that the composite metric correctly rewards *efficiency and reliability*, not just raw output.

---

## Key Takeaways / What I Learned

- Designing a normalized schema (separate `matches` and `deliveries` tables linked by foreign key) rather than one flat file
- Using window functions (`RANK`, running `SUM() OVER`) to answer "who's best, and by how much" questions
- Building multi-CTE queries to combine several performance dimensions into one composite score
- Validating data completeness before trusting results (catching the 2018–2019 ball-by-ball gap)
- Distinguishing statistically reliable findings from small-sample outliers throughout the analysis

## Author
Pooja — [LinkedIn] · [GitHub]
