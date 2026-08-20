DROP TABLE IF EXISTS transformed_prod_match_team_stats;
CREATE TEMP TABLE transformed_prod_match_team_stats AS
WITH rows_to_columns AS
(
SELECT 
fixture_id
,team_id
,REPLACE(TRIM(LOWER(stat_type)), ' ', '_') stat_type
,stat_value
,CASE WHEN REPLACE(TRIM(LOWER(stat_type)), ' ', '_')='shots_on_goal' THEN stat_value ELSE 0 END shots_on_goal 
,CASE WHEN REPLACE(TRIM(LOWER(stat_type)), ' ', '_')='shots_off_goal' THEN stat_value ELSE 0 END shots_off_goal 
,CASE WHEN REPLACE(TRIM(LOWER(stat_type)), ' ', '_')='total_shots' THEN stat_value ELSE 0 END total_shots 
,CASE WHEN REPLACE(TRIM(LOWER(stat_type)), ' ', '_')='blocked_shots' THEN stat_value ELSE 0 END blocked_shots 
,CASE WHEN REPLACE(TRIM(LOWER(stat_type)), ' ', '_')='shots_insidebox' THEN stat_value ELSE 0 END shots_insidebox 
,CASE WHEN REPLACE(TRIM(LOWER(stat_type)), ' ', '_')='shots_outsidebox' THEN stat_value ELSE 0 END shots_outsidebox 
,CASE WHEN REPLACE(TRIM(LOWER(stat_type)), ' ', '_')='fouls' THEN stat_value ELSE 0 END fouls 
,CASE WHEN REPLACE(TRIM(LOWER(stat_type)), ' ', '_')='corner_kicks' THEN stat_value ELSE 0 END corner_kicks 
,CASE WHEN REPLACE(TRIM(LOWER(stat_type)), ' ', '_')='offsides' THEN stat_value ELSE 0 END offsides 
,CASE WHEN REPLACE(TRIM(LOWER(stat_type)), ' ', '_')='ball_possession' THEN stat_value ELSE 0 END ball_possession 
,CASE WHEN REPLACE(TRIM(LOWER(stat_type)), ' ', '_')='yellow_cards' THEN stat_value ELSE 0 END yellow_cards 
,CASE WHEN REPLACE(TRIM(LOWER(stat_type)), ' ', '_')='red_cards' THEN stat_value ELSE 0 END red_cards 
,CASE WHEN REPLACE(TRIM(LOWER(stat_type)), ' ', '_')='goalkeeper_saves' THEN stat_value ELSE 0 END goalkeeper_saves 
,CASE WHEN REPLACE(TRIM(LOWER(stat_type)), ' ', '_')='total_passes' THEN stat_value ELSE 0 END total_passes 
,CASE WHEN REPLACE(TRIM(LOWER(stat_type)), ' ', '_')='passes_accurate' THEN stat_value ELSE 0 END passes_accurate 
,CASE WHEN REPLACE(TRIM(LOWER(stat_type)), ' ', '_')='passes_%' THEN stat_value ELSE 0 END passes_perc
,CASE WHEN REPLACE(TRIM(LOWER(stat_type)), ' ', '_')='expected_goals' THEN stat_value ELSE 0 END expected_goals 
,CASE WHEN REPLACE(TRIM(LOWER(stat_type)), ' ', '_')='goals_prevented' THEN stat_value ELSE 0 END goals_prevented  
FROM prod_match_team_stats
)
SELECT
fixture_id
,team_id
,SUM(shots_on_goal) shots_on_goal
,SUM(shots_off_goal) shots_off_goal
,SUM(total_shots) total_shots
,SUM(blocked_shots) blocked_shots
,SUM(shots_insidebox) shots_insidebox
,SUM(shots_outsidebox) shots_outsidebox
,SUM(fouls) fouls
,SUM(corner_kicks) corner_kicks
,SUM(offsides) offsides
,SUM(ball_possession) ball_possession
,SUM(yellow_cards) yellow_cards
,SUM(red_cards) red_cards
,SUM(goalkeeper_saves) goalkeeper_saves
,SUM(total_passes) total_passes
,SUM(passes_accurate) passes_accurate
,SUM(passes_perc) passes_perc
,SUM(expected_goals) expected_goals
,SUM(goals_prevented) goals_prevented
FROM rows_to_columns
GROUP BY 1,2;

DROP TABLE IF EXISTS transformed_prod_match_events;
CREATE TEMP TABLE transformed_prod_match_events AS
WITH rows_to_columns AS
(
SELECT 
fixture_id
,team_id
,detail
,CASE WHEN REPLACE(TRIM(LOWER(detail)),' ','_') ='card_reviewed' THEN 1 ELSE 0 END card_reviewed
,CASE WHEN REPLACE(TRIM(LOWER(detail)),' ','_') ='card_upgrade' THEN 1 ELSE 0 END card_upgrade
,CASE WHEN REPLACE(TRIM(LOWER(detail)),' ','_') ='goal_cancelled' THEN 1 ELSE 0 END goal_cancelled
,CASE WHEN REPLACE(TRIM(LOWER(detail)),' ','_') ='goal_confirmed' THEN 1 ELSE 0 END goal_confirmed
,CASE WHEN REPLACE(TRIM(LOWER(detail)),' ','_') ='goal_disallowed' THEN 1 ELSE 0 END goal_disallowed
,CASE WHEN REPLACE(TRIM(LOWER(detail)),' ','_') ='goal_disallowed_foul' THEN 1 ELSE 0 END goal_disallowed_foul
,CASE WHEN REPLACE(TRIM(LOWER(detail)),' ','_') ='goal_disallowed_handball' THEN 1 ELSE 0 END goal_disallowed_handball
,CASE WHEN REPLACE(TRIM(LOWER(detail)),' ','_') ='goal_disallowed_offside' THEN 1 ELSE 0 END goal_disallowed_offside
,CASE WHEN REPLACE(TRIM(LOWER(detail)),' ','_') ='missed_penalty' THEN 1 ELSE 0 END missed_penalty
,CASE WHEN REPLACE(TRIM(LOWER(detail)),' ','_') ='normal_goal' THEN 1 ELSE 0 END normal_goal
,CASE WHEN REPLACE(TRIM(LOWER(detail)),' ','_') ='own_goal' THEN 1 ELSE 0 END own_goal
,CASE WHEN REPLACE(TRIM(LOWER(detail)),' ','_') ='penalty' THEN 1 ELSE 0 END penalty
,CASE WHEN REPLACE(TRIM(LOWER(detail)),' ','_') ='penalty_awarded' THEN 1 ELSE 0 END penalty_awarded
,CASE WHEN REPLACE(TRIM(LOWER(detail)),' ','_') ='penalty_cancelled' THEN 1 ELSE 0 END penalty_cancelled
,CASE WHEN REPLACE(TRIM(LOWER(detail)),' ','_') ='penalty_confirmed' THEN 1 ELSE 0 END penalty_confirmed
,CASE WHEN REPLACE(TRIM(LOWER(detail)),' ','_') ='red_card' THEN 1 ELSE 0 END red_card
,CASE WHEN REPLACE(TRIM(LOWER(detail)),' ','_') ='red_card_cancelled' THEN 1 ELSE 0 END red_card_cancelled
,CASE WHEN REPLACE(TRIM(LOWER(detail)),' ','_') ='substitution_1' THEN 1 ELSE 0 END substitution_1
,CASE WHEN REPLACE(TRIM(LOWER(detail)),' ','_') ='substitution_10' THEN 1 ELSE 0 END substitution_10
,CASE WHEN REPLACE(TRIM(LOWER(detail)),' ','_') ='substitution_11' THEN 1 ELSE 0 END substitution_11
,CASE WHEN REPLACE(TRIM(LOWER(detail)),' ','_') ='substitution_12' THEN 1 ELSE 0 END substitution_12
,CASE WHEN REPLACE(TRIM(LOWER(detail)),' ','_') ='substitution_13' THEN 1 ELSE 0 END substitution_13
,CASE WHEN REPLACE(TRIM(LOWER(detail)),' ','_') ='substitution_14' THEN 1 ELSE 0 END substitution_14
,CASE WHEN REPLACE(TRIM(LOWER(detail)),' ','_') ='substitution_15' THEN 1 ELSE 0 END substitution_15
,CASE WHEN REPLACE(TRIM(LOWER(detail)),' ','_') ='substitution_16' THEN 1 ELSE 0 END substitution_16
,CASE WHEN REPLACE(TRIM(LOWER(detail)),' ','_') ='substitution_17' THEN 1 ELSE 0 END substitution_17
,CASE WHEN REPLACE(TRIM(LOWER(detail)),' ','_') ='substitution_18' THEN 1 ELSE 0 END substitution_18
,CASE WHEN REPLACE(TRIM(LOWER(detail)),' ','_') ='substitution_2' THEN 1 ELSE 0 END substitution_2
,CASE WHEN REPLACE(TRIM(LOWER(detail)),' ','_') ='substitution_3' THEN 1 ELSE 0 END substitution_3
,CASE WHEN REPLACE(TRIM(LOWER(detail)),' ','_') ='substitution_4' THEN 1 ELSE 0 END substitution_4
,CASE WHEN REPLACE(TRIM(LOWER(detail)),' ','_') ='substitution_5' THEN 1 ELSE 0 END substitution_5
,CASE WHEN REPLACE(TRIM(LOWER(detail)),' ','_') ='substitution_6' THEN 1 ELSE 0 END substitution_6
,CASE WHEN REPLACE(TRIM(LOWER(detail)),' ','_') ='substitution_7' THEN 1 ELSE 0 END substitution_7
,CASE WHEN REPLACE(TRIM(LOWER(detail)),' ','_') ='substitution_8' THEN 1 ELSE 0 END substitution_8
,CASE WHEN REPLACE(TRIM(LOWER(detail)),' ','_') ='substitution_9' THEN 1 ELSE 0 END substitution_9
,CASE WHEN REPLACE(TRIM(LOWER(detail)),' ','_') ='yellow_card' THEN 1 ELSE 0 END yellow_card
FROM prod_match_events
)
SELECT
fixture_id
,team_id
,SUM(card_reviewed) card_reviewed
,SUM(card_upgrade) card_upgrade
,SUM(goal_cancelled) goal_cancelled
,SUM(goal_confirmed) goal_confirmed
,SUM(goal_disallowed) goal_disallowed
,SUM(goal_disallowed_foul) goal_disallowed_foul
,SUM(goal_disallowed_handball) goal_disallowed_handball
,SUM(goal_disallowed_offside) goal_disallowed_offside
,SUM(missed_penalty) missed_penalty
,SUM(normal_goal) normal_goal
,SUM(own_goal) own_goal
,SUM(penalty) penalty
,SUM(penalty_awarded) penalty_awarded
,SUM(penalty_cancelled) penalty_cancelled
,SUM(penalty_confirmed) penalty_confirmed
,SUM(red_card) red_card
,SUM(red_card_cancelled) red_card_cancelled
,SUM(substitution_1) substitution_1
,SUM(substitution_10) substitution_10
,SUM(substitution_11) substitution_11
,SUM(substitution_12) substitution_12
,SUM(substitution_13) substitution_13
,SUM(substitution_14) substitution_14
,SUM(substitution_15) substitution_15
,SUM(substitution_16) substitution_16
,SUM(substitution_17) substitution_17
,SUM(substitution_18) substitution_18
,SUM(substitution_2) substitution_2
,SUM(substitution_3) substitution_3
,SUM(substitution_4) substitution_4
,SUM(substitution_5) substitution_5
,SUM(substitution_6) substitution_6
,SUM(substitution_7) substitution_7
,SUM(substitution_8) substitution_8
,SUM(substitution_9) substitution_9
,SUM(yellow_card) yellow_card
FROM rows_to_columns
GROUP BY 1,2;


DROP TABLE IF EXISTS transformed_prod_match_player_stats;
CREATE TEMP TABLE transformed_prod_match_player_stats AS
SELECT
fixture_id
,team_id
--,team_name
--,avg(player_id) player_id
--,player_name
,AVG(games_minutes) games_minutes
--,games_number
--,games_position
--,games_rating
--,games_captain
--,games_substitute
,SUM(offsides) offsides
,SUM(shots_total) shots_total
,SUM(shots_on) shots_on
,SUM(goals_total) goals_total
,SUM(goals_conceded) goals_conceded
,SUM(goals_assists) goals_assists
,SUM(goals_saves) goals_saves
,SUM(passes_total) passes_total
,SUM(passes_key) passes_key
,AVG(substring(passes_accuracy FROM '^([0-9]+(?:\.[0-9]+)?)(?:%)?$')::float) passes_accuracy
,SUM(tackles_total) tackles_total
,SUM(tackles_blocks) tackles_blocks
,SUM(tackles_interceptions) tackles_interceptions
,SUM(duels_total) duels_total
,SUM(duels_won) duels_won
,SUM(dribbles_attempts) dribbles_attempts
,SUM(dribbles_success) dribbles_success
,SUM(dribbles_past) dribbles_past
,SUM(fouls_drawn) fouls_drawn
,SUM(fouls_committed) fouls_committed
,SUM(cards_yellow) cards_yellow
,SUM(cards_red) cards_red
,SUM(penalty_won) penalty_won
,SUM(penalty_commited) penalty_commited
,SUM(penalty_scored) penalty_scored
,SUM(penalty_missed) penalty_missed
,SUM(penalty_saved) penalty_saved
FROM prod_match_player_stats
--WHERE fixture_id = 1334277
GROUP BY 1,2;

DROP TABLE IF EXISTS transformed_prod_match_summary;
CREATE TEMP TABLE transformed_prod_match_summary AS
WITH filter_observations AS
(
SELECT *
FROM prod_match_summary
WHERE (home_winner = TRUE AND away_winner = FALSE) 
	OR (home_winner = FALSE AND away_winner = TRUE)
	OR (home_winner = FALSE AND away_winner = FALSE)
),split_home_away_rows AS
(
SELECT
t1.fixture_id
,t1.date
,t1.venue_id
,t1.venue_name
,t1.status_elapsed
,t1.status_extra
,t1.league_id
,t1.home_team_id team_id
,t1.home_goals goals
,t1.home_winner is_winner
,t1.league_season
,1 is_home
FROM filter_observations t1
WHERE (home_winner = TRUE) 
	OR (away_winner = TRUE AND home_winner = FALSE)
	OR (home_winner = FALSE AND away_winner = FALSE)
UNION
SELECT
t1.fixture_id
,t1.date
,t1.venue_id
,t1.venue_name
,t1.status_elapsed
,t1.status_extra
,t1.league_id
,t1.away_team_id team_id
,t1.away_goals goals
,t1.away_winner is_winner
,t1.league_season
,0 is_home
FROM filter_observations t1
WHERE (away_winner = TRUE)
	OR (away_winner = FALSE AND home_winner = TRUE)
	OR (home_winner = FALSE AND away_winner = FALSE)
)
SELECT

t1.fixture_id
,t1.date
,t1.venue_id
,t1.venue_name
,t1.status_elapsed
,t1.status_extra
,t1.league_id
,t1.team_id
,t1.goals
,t1.is_winner
,t1.is_home
,t1.league_season

,t2.shots_on_goal
,t2.shots_off_goal
,t2.total_shots
,t2.blocked_shots
,t2.shots_insidebox
,t2.shots_outsidebox
,t2.fouls
,t2.corner_kicks
,t2.offsides
,t2.ball_possession
,t2.yellow_cards
,t2.red_cards
,t2.goalkeeper_saves
,t2.total_passes
,t2.passes_accurate
,t2.passes_perc
--,t2.expected_goals
,t2.goals_prevented

,t3.card_reviewed
,t3.card_upgrade
,t3.goal_cancelled
,t3.goal_confirmed
,t3.goal_disallowed
,t3.goal_disallowed_foul
,t3.goal_disallowed_handball
,t3.goal_disallowed_offside
,t3.missed_penalty
,t3.normal_goal
,t3.own_goal
,t3.penalty
,t3.penalty_awarded
,t3.penalty_cancelled
,t3.penalty_confirmed
,t3.red_card
,t3.red_card_cancelled
,t3.substitution_1
,t3.substitution_10
,t3.substitution_11
,t3.substitution_12
,t3.substitution_13
,t3.substitution_14
,t3.substitution_15
,t3.substitution_16
,t3.substitution_17
,t3.substitution_18
,t3.substitution_2
,t3.substitution_3
,t3.substitution_4
,t3.substitution_5
,t3.substitution_6
,t3.substitution_7
,t3.substitution_8
,t3.substitution_9
,t3.yellow_card

,t4.games_minutes
,t4.offsides t4_offsides
,t4.shots_total
,t4.shots_on
,t4.goals_total
,t4.goals_conceded
,t4.goals_assists
,t4.goals_saves
,t4.passes_total
,t4.passes_key
,t4.passes_accuracy
,t4.tackles_total
,t4.tackles_blocks
,t4.tackles_interceptions
,t4.duels_total
,t4.duels_won
,t4.dribbles_attempts
,t4.dribbles_success
,t4.dribbles_past
,t4.fouls_drawn
,t4.fouls_committed
,t4.cards_yellow
,t4.cards_red
,t4.penalty_won
,t4.penalty_commited
,t4.penalty_scored
,t4.penalty_missed
,t4.penalty_saved
FROM split_home_away_rows t1
INNER JOIN transformed_prod_match_team_stats t2 ON t1.fixture_id = t2.fixture_id AND t1.team_id = t2.team_id
INNER JOIN transformed_prod_match_events t3 ON t1.fixture_id = t3.fixture_id AND t1.team_id = t3.team_id
INNER JOIN transformed_prod_match_player_stats t4 ON t1.fixture_id = t4.fixture_id AND t1.team_id = t4.team_id
;

DROP TABLE IF EXISTS gpg_calculation_per_team;
CREATE TEMP TABLE gpg_calculation_per_team AS
WITH total_goals_per_season AS
(
SELECT 
league_season
,is_home
,COUNT(fixture_id) total_season_matches
,SUM(goals) total_season_goals
,SUM(goals_conceded) total_season_goals_conceded
FROM transformed_prod_match_summary
WHERE league_id = 128
GROUP BY 1,2
), total_goals_per_team_season AS
(
SELECT 
t1.team_id
,t1.league_season
,is_home
,COUNT(t1.fixture_id) total_matches
,SUM(t1.goals) total_goals
,SUM(goals_conceded) total_goals_conceded
FROM transformed_prod_match_summary t1
WHERE league_id = 128
GROUP BY 1,2,3
), team_totals AS
(
SELECT
t1.team_id
,t1.league_season
,t1.is_home
,t1.total_goals
,t1.total_matches
,t1.total_goals_conceded
,t2.total_season_goals
,t2.total_season_goals_conceded
,t2.total_season_matches
FROM total_goals_per_team_season t1
INNER JOIN total_goals_per_season t2 ON t1.is_home = t2.is_home AND t1.league_season = t2.league_season
), gpg_per_team_union AS
(
SELECT
team_id
,league_season
,is_home
,total_season_goals
,total_season_matches
,total_season_goals_conceded
,total_goals home_total_goals
,total_goals_conceded home_total_goals_conceded
,total_matches home_total_matches
,0 away_total_goals
,0 away_total_goals_conceded
,0 away_total_matches
, total_goals/total_matches home_gpg_scored
, total_goals_conceded/total_matches home_gpg_conceded
, 0 away_gpg_scored
, 0 away_gpg_conceded
FROM team_totals
WHERE is_home = 1
UNION
SELECT
team_id
,league_season
,is_home
,total_season_goals
,total_season_matches
,total_season_goals_conceded
,0 home_total_goals
,0 home_total_goals_conceded
,0 home_total_matches
,total_goals away_total_goals
,total_goals_conceded away_total_goals_conceded
,total_matches away_total_matches
, 0 home_gpg_scored
, 0 home_gpg_conceded
, total_goals/total_matches away_gpg_scored
, total_goals_conceded/total_matches away_gpg_conceded
FROM team_totals
WHERE is_home = 0
)
SELECT
team_id
,league_season
, SUM(total_season_goals) total_season_goals
, SUM(total_season_goals_conceded) total_season_goals_conceded
, SUM(total_season_matches) total_season_matches
, SUM(home_total_goals) home_total_goals
, SUM(home_total_goals_conceded) home_total_goals_conceded
, SUM(home_total_matches) home_total_matches
, SUM(away_total_goals) away_total_goals
, SUM(away_total_goals_conceded) away_total_goals_conceded
, SUM(away_total_matches) away_total_matches
, SUM(home_gpg_scored) home_gpg_scored
, SUM(home_gpg_conceded) home_gpg_conceded
, SUM(away_gpg_scored) away_gpg_scored
, SUM(away_gpg_conceded) away_gpg_conceded
FROM gpg_per_team_union
GROUP BY 1,2
;

DROP TABLE IF EXISTS xG_calculation_per_team;
CREATE TEMP TABLE xG_calculation_per_team AS
WITH totals_per_season_and_team AS
(
SELECT
team_id
,league_season
,total_season_goals
,total_season_goals_conceded
,total_season_matches
,home_total_goals
,home_total_goals_conceded
,home_total_matches
,away_total_goals
,away_total_goals_conceded
,away_total_matches
,home_gpg_scored
,home_gpg_conceded
,away_gpg_scored
,away_gpg_conceded
,SUM(home_total_goals) 			OVER (PARTITION BY league_season)/SUM(home_total_matches) OVER (PARTITION BY league_season) avg_league_home_gpg_scored
,SUM(home_total_goals_conceded) OVER (PARTITION BY league_season)/SUM(home_total_matches) OVER (PARTITION BY league_season) avg_league_home_gpg_conceded
,SUM(away_total_goals) 			OVER (PARTITION BY league_season)/SUM(away_total_matches) OVER (PARTITION BY league_season) avg_league_away_gpg_scored
,SUM(away_total_goals_conceded) OVER (PARTITION BY league_season)/SUM(away_total_matches) OVER (PARTITION BY league_season) avg_league_away_gpg_conceded
FROM gpg_calculation_per_team
)
SELECT
team_id
,league_season
,total_season_goals
,total_season_goals_conceded
,total_season_matches
,home_total_goals
,home_total_goals_conceded
,home_total_matches
,away_total_goals
,away_total_goals_conceded
,away_total_matches
,home_gpg_scored
,home_gpg_conceded
,away_gpg_scored
,away_gpg_conceded
,avg_league_home_gpg_scored
,avg_league_home_gpg_conceded
,avg_league_away_gpg_scored
,avg_league_away_gpg_conceded
,home_gpg_scored/avg_league_home_gpg_scored home_attack
,away_gpg_conceded/avg_league_away_gpg_conceded away_defence
,away_gpg_scored/avg_league_away_gpg_scored away_attack
,home_gpg_conceded/avg_league_home_gpg_conceded home_defence
FROM totals_per_season_and_team
WHERE league_season <= 2024;

SELECT
*
FROM xG_calculation_per_team;

SELECT
league_season
, AVG(home_attack) avg_home_attack
, AVG(home_defence) avg_home_defence
, AVG(away_attack) avg_away_attack
, AVG(away_defence) avg_away_defence
FROM xG_calculation_per_team
GROUP BY 1
ORDER BY 1 ASC;

-- Relative strengths don't drift per season, they stay very stable
-- So, it doesn't seem like the league is getting stronger or weaker over time, 
-- at least not in a way that is captured by the relative strength of teams. 