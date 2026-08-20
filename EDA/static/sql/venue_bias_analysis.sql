-----------------------
-- Team Venue Dependant / Winning Observations Composition
-----------------------

CREATE TEMP TABLE teams_winrate AS
WITH home_wins_data AS
(
	SELECT home_team_id team_id
	, SUM(CASE WHEN home_winner = TRUE THEN 1 ELSE 0 END) home_wins
	, COUNT(*) total_home_matches
	FROM prod_match_summary 
	WHERE league_id = 128 AND EXTRACT(YEAR FROM date) <= 2024 -- 2025 and 2026 are val, test and oot
	GROUP BY 1
), away_wins_data AS
(
	SELECT away_team_id team_id
	, SUM(CASE WHEN away_winner = TRUE THEN 1 ELSE 0 END) away_wins
	, COUNT(*) total_away_matches
	FROM prod_match_summary
	WHERE league_id = 128 AND EXTRACT(YEAR FROM date) <= 2024 -- 2025 and 2026 are val, test and oot
	GROUP BY 1
), away_home_union AS
(
SELECT team_id
, home_wins
, total_home_matches
, 0 away_wins
, 0 total_away_matches
FROM home_wins_data
UNION
SELECT team_id
, 0 home_wins
, 0 total_home_matches
, away_wins
, total_away_matches
FROM away_wins_data
), grouped_by_totals AS
(
SELECT
team_id
, SUM(total_home_matches+total_away_matches) total_matches -- Validate this is the same as total_home_matches+total_away_matches
, SUM(home_wins) home_wins
, SUM(total_home_matches) total_home_matches
, SUM(away_wins) away_wins
, SUM(total_away_matches) total_away_matches
FROM away_home_union
GROUP BY 1
), teams_name AS
(
select team_id, TRIM(LOWER(team_name)) team_name
from prod_match_teams
GROUP BY 1,2
)
SELECT
t1.team_id
,team_name
,home_wins::numeric/total_home_matches home_winrate
,home_wins
,total_home_matches
,away_wins::numeric/total_away_matches away_winrate
,away_wins
,total_away_matches
,(home_wins::numeric/total_home_matches) - (away_wins::numeric/total_away_matches) dif_home_away
,total_matches
FROM grouped_by_totals t1
INNER JOIN teams_name t2 ON t1.team_id = t2.team_id
ORDER BY 9 DESC;

-- Winning samples composition:

-- 52% of the teams win mostly as locals
-- 48% of the teams have almost the same winrate at home and away
-- There are no teams that win mostly away

-- If we set a threshold for "teams that mostly win at home" as dif_home_away >= 0.15
-- which represents a 15% difference between  home winrate and away winrate, the teams on each side of the inequality
-- are consolidated ones (or important ones) in first division, middle or small ones and new teams which shows 
-- that theres no clear pattern or bias (good representativity in the samples) for mostly winning home
-- or having a balanced winrate at home and away

-- Additionally, all teams seem to representativity (at first glance) in both the winning away and winning home samples.
-- Of course there are teams with more matches played and won, but the distribution of the teams in both samples seems to be good enough to not apply 
--  any sampling technique right away

-- I would not apply any sampling method right away since the numbers
-- make sense. I would like the model to learn that winning away
-- is rarer than winning home and sharing points happens pretty much 1/3 of the time
-- which is a good thing since it's the default option

-----------------------
-- Team Venue Dependant / Winning Observations Composition -- USING OTHER CATEGORIZATION CRITERIA
-----------------------

-- Check winning composition for both home and away matches

-- if we categorize by dif_home_away >= 0.15, then winning composition is pretty
-- much 50/50. So, we get as much representation for venue biased teams as for balanced ones
-- Therefore, our winning targets won't be biased towards either
WITH teams_categorized AS
(
SELECT
*
,	CASE
		WHEN dif_home_away >= 0.15 THEN 'venue_biased'
		ELSE 'balanced'
	END category
FROM
teams_winrate
)
SELECT category, SUM(home_wins) home_wins, SUM(away_wins) away_wins
FROM teams_categorized
GROUP BY 1;

-- if we categorize by total_matches as a proxy for how consolidated a team is in first division, 
-- then winning composition is also well represented across the 3 groups. So, no bias towards big teams
-- or consolidated ones or less representation for newly promoted or non-consolidated teams

WITH total_matches_q_dist AS
(
SELECT
PERCENTILE_CONT(0.0) WITHIN GROUP (ORDER BY total_matches) min_value
, PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY total_matches) p_25
, PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY total_matches) p_50
, PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY total_matches) p_75
, PERCENTILE_CONT(1) WITHIN GROUP (ORDER BY total_matches) max_value
FROM teams_winrate
)
SELECT
team_name
,home_wins
,away_wins
,total_matches
, 	CASE
		WHEN total_matches < p_50 THEN 'not_consolidated'
		WHEN total_matches BETWEEN p_50 AND p_75 THEN 'consolidated'
		ELSE 'big_teams'
	END category
,dif_home_away
FROM
teams_winrate
CROSS JOIN total_matches_q_dist
ORDER BY 4;

WITH total_matches_q_dist AS
(
SELECT
PERCENTILE_CONT(0.0) WITHIN GROUP (ORDER BY total_matches) min_value
, PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY total_matches) p_25
, PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY total_matches) p_50
, PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY total_matches) p_75
, PERCENTILE_CONT(1) WITHIN GROUP (ORDER BY total_matches) max_value
FROM teams_winrate
),teams_categorized AS
(
SELECT
*
, 	CASE
		WHEN total_matches < p_50 THEN 'not_consolidated'
		WHEN total_matches BETWEEN p_50 AND p_75 THEN 'consolidated'
		ELSE 'big_teams'
	END category
FROM
teams_winrate
CROSS JOIN total_matches_q_dist
)
SELECT category, SUM(home_wins) home_wins, SUM(away_wins) away_wins
FROM teams_categorized
GROUP BY 1;