-----------------------
-- Target stability Check
-----------------------

-- The amount of matches played increases over time, which is expected

SELECT 
EXTRACT(YEAR FROM date) f_analisis
,CASE
	WHEN home_winner = TRUE AND away_winner = FALSE THEN 'home_win'
	WHEN home_winner IS NULL AND away_winner IS NULL THEN 'draw'
	WHEN home_winner = FALSE AND away_winner = TRUE THEN 'away_win'
END target
, COUNT(*)
FROM prod_match_summary
WHERE league_id = 128
GROUP BY 1,2
ORDER BY 2 ASC, 1 ASC;

-- It seems to be related to
-- the fact that more teams are playing
-- in first division

SELECT 
EXTRACT(YEAR FROM date) f_analisis
, COUNT(DISTINCT home_team_id)
, COUNT(DISTINCT away_team_id)
, COUNT(*)
FROM prod_match_summary
WHERE league_id = 128
GROUP BY 1
ORDER BY 1 ASC;

-- In recent years, away_win (or home_lose) has gone down
-- while draw and home_win have either increased or stay almost constant
-- The tendency is the opposite between draw and away_win which
-- might suggest training from 2021 (lagging up to 2 years) and
-- validating with first half of 2025 and test with second half of 2025
-- out-of-time would be the entire 2026

WITH totals_by_win_type AS
(
SELECT
EXTRACT(YEAR FROM date) f_analisis
, SUM(CASE WHEN home_winner = TRUE AND away_winner = FALSE THEN 1 ELSE 0 END) home_win
, SUM(CASE WHEN home_winner IS NULL AND away_winner IS NULL THEN 1 ELSE 0 END) draw
, SUM(CASE WHEN home_winner = FALSE AND away_winner = TRUE THEN 1 ELSE 0 END) away_win
, COUNT(*) total_matches
FROM prod_match_summary
WHERE league_id = 128
GROUP BY 1
ORDER BY 1 ASC
)
SELECT 
f_analisis
,ROUND(((home_win::float/total_matches)*100)::numeric,1) home_win_perc
,ROUND(((draw::float/total_matches)*100)::numeric,1) draw_perc
,ROUND(((away_win::float/total_matches)*100)::numeric,1) away_win_perc
, total_matches
FROM totals_by_win_type
;

-- Class imbalance is not really that bad
-- home_win is around 50% of the total matches, 
-- draw is around 30% and away_win is around 25%

-- I would suggest not applying any class imbalance technique
-- right away

-- Also, draw could be treated as the 0 class, home win as the 2 class and away win as the 1 class