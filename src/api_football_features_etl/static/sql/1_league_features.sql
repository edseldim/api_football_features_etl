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
WHERE t1.league_id = 128
;

-- LAGs

DROP TABLE IF EXISTS transformed_prod_match_summary_lags;
CREATE TEMP TABLE transformed_prod_match_summary_lags AS
WITH lagged_data AS
(
SELECT
fixture_id
,date
,venue_id
,venue_name
,status_elapsed
,status_extra
,league_id
,team_id
,goals
,is_winner
,is_home
,league_season
,shots_on_goal
,shots_off_goal
,total_shots
,blocked_shots
,shots_insidebox
,shots_outsidebox
,fouls
,corner_kicks
,offsides
,ball_possession
,yellow_cards
,red_cards
,goalkeeper_saves
,total_passes
,passes_accurate
,passes_perc
,goals_prevented
,card_reviewed
,card_upgrade
,goal_cancelled
,goal_confirmed
,goal_disallowed
,goal_disallowed_foul
,goal_disallowed_handball
,goal_disallowed_offside
,missed_penalty
,normal_goal
,own_goal
,penalty
,penalty_awarded
,penalty_cancelled
,penalty_confirmed
,red_card
,red_card_cancelled
,substitution_1
,substitution_10
,substitution_11
,substitution_12
,substitution_13
,substitution_14
,substitution_15
,substitution_16
,substitution_17
,substitution_18
,substitution_2
,substitution_3
,substitution_4
,substitution_5
,substitution_6
,substitution_7
,substitution_8
,substitution_9
,yellow_card
,games_minutes
,shots_total
,shots_on
,goals_total
,goals_conceded
,goals_assists
,goals_saves
,passes_total
,passes_key
,passes_accuracy
,tackles_total
,tackles_blocks
,tackles_interceptions
,duels_total
,duels_won
,dribbles_attempts
,dribbles_success
,dribbles_past
,fouls_drawn
,fouls_committed
,cards_yellow
,cards_red
,penalty_won
,penalty_commited
,penalty_scored
,penalty_missed
,penalty_saved
,LAG(date,1) OVER w1 AS date_1
,LAG(date,2) OVER w1 AS date_2
,LAG(date,3) OVER w1 AS date_3
,LAG(date,4) OVER w1 AS date_4
,LAG(goals,1) OVER w1 AS lag_goals_1
,LAG(goals,2) OVER w1 AS lag_goals_2
,LAG(goals,3) OVER w1 AS lag_goals_3
,LAG(goals,4) OVER w1 AS lag_goals_4
,LAG(is_winner,1) OVER w1 AS lag_is_winner_1
,LAG(is_winner,2) OVER w1 AS lag_is_winner_2
,LAG(is_winner,3) OVER w1 AS lag_is_winner_3
,LAG(is_winner,4) OVER w1 AS lag_is_winner_4
,LAG(is_home,1) OVER w1 AS lag_is_home_1
,LAG(is_home,2) OVER w1 AS lag_is_home_2
,LAG(is_home,3) OVER w1 AS lag_is_home_3
,LAG(is_home,4) OVER w1 AS lag_is_home_4
,LAG(shots_on_goal,1) OVER w1 AS lag_shots_on_goal_1
,LAG(shots_on_goal,2) OVER w1 AS lag_shots_on_goal_2
,LAG(shots_on_goal,3) OVER w1 AS lag_shots_on_goal_3
,LAG(shots_on_goal,4) OVER w1 AS lag_shots_on_goal_4
,LAG(shots_off_goal,1) OVER w1 AS lag_shots_off_goal_1
,LAG(shots_off_goal,2) OVER w1 AS lag_shots_off_goal_2
,LAG(shots_off_goal,3) OVER w1 AS lag_shots_off_goal_3
,LAG(shots_off_goal,4) OVER w1 AS lag_shots_off_goal_4
,LAG(total_shots,1) OVER w1 AS lag_total_shots_1
,LAG(total_shots,2) OVER w1 AS lag_total_shots_2
,LAG(total_shots,3) OVER w1 AS lag_total_shots_3
,LAG(total_shots,4) OVER w1 AS lag_total_shots_4
,LAG(blocked_shots,1) OVER w1 AS lag_blocked_shots_1
,LAG(blocked_shots,2) OVER w1 AS lag_blocked_shots_2
,LAG(blocked_shots,3) OVER w1 AS lag_blocked_shots_3
,LAG(blocked_shots,4) OVER w1 AS lag_blocked_shots_4
,LAG(shots_insidebox,1) OVER w1 AS lag_shots_insidebox_1
,LAG(shots_insidebox,2) OVER w1 AS lag_shots_insidebox_2
,LAG(shots_insidebox,3) OVER w1 AS lag_shots_insidebox_3
,LAG(shots_insidebox,4) OVER w1 AS lag_shots_insidebox_4
,LAG(shots_outsidebox,1) OVER w1 AS lag_shots_outsidebox_1
,LAG(shots_outsidebox,2) OVER w1 AS lag_shots_outsidebox_2
,LAG(shots_outsidebox,3) OVER w1 AS lag_shots_outsidebox_3
,LAG(shots_outsidebox,4) OVER w1 AS lag_shots_outsidebox_4
,LAG(fouls,1) OVER w1 AS lag_fouls_1
,LAG(fouls,2) OVER w1 AS lag_fouls_2
,LAG(fouls,3) OVER w1 AS lag_fouls_3
,LAG(fouls,4) OVER w1 AS lag_fouls_4
,LAG(corner_kicks,1) OVER w1 AS lag_corner_kicks_1
,LAG(corner_kicks,2) OVER w1 AS lag_corner_kicks_2
,LAG(corner_kicks,3) OVER w1 AS lag_corner_kicks_3
,LAG(corner_kicks,4) OVER w1 AS lag_corner_kicks_4
,LAG(offsides,1) OVER w1 AS lag_offsides_1
,LAG(offsides,2) OVER w1 AS lag_offsides_2
,LAG(offsides,3) OVER w1 AS lag_offsides_3
,LAG(offsides,4) OVER w1 AS lag_offsides_4
,LAG(ball_possession,1) OVER w1 AS lag_ball_possession_1
,LAG(ball_possession,2) OVER w1 AS lag_ball_possession_2
,LAG(ball_possession,3) OVER w1 AS lag_ball_possession_3
,LAG(ball_possession,4) OVER w1 AS lag_ball_possession_4
,LAG(yellow_cards,1) OVER w1 AS lag_yellow_cards_1
,LAG(yellow_cards,2) OVER w1 AS lag_yellow_cards_2
,LAG(yellow_cards,3) OVER w1 AS lag_yellow_cards_3
,LAG(yellow_cards,4) OVER w1 AS lag_yellow_cards_4
,LAG(red_cards,1) OVER w1 AS lag_red_cards_1
,LAG(red_cards,2) OVER w1 AS lag_red_cards_2
,LAG(red_cards,3) OVER w1 AS lag_red_cards_3
,LAG(red_cards,4) OVER w1 AS lag_red_cards_4
,LAG(goalkeeper_saves,1) OVER w1 AS lag_goalkeeper_saves_1
,LAG(goalkeeper_saves,2) OVER w1 AS lag_goalkeeper_saves_2
,LAG(goalkeeper_saves,3) OVER w1 AS lag_goalkeeper_saves_3
,LAG(goalkeeper_saves,4) OVER w1 AS lag_goalkeeper_saves_4
,LAG(total_passes,1) OVER w1 AS lag_total_passes_1
,LAG(total_passes,2) OVER w1 AS lag_total_passes_2
,LAG(total_passes,3) OVER w1 AS lag_total_passes_3
,LAG(total_passes,4) OVER w1 AS lag_total_passes_4
,LAG(passes_accurate,1) OVER w1 AS lag_passes_accurate_1
,LAG(passes_accurate,2) OVER w1 AS lag_passes_accurate_2
,LAG(passes_accurate,3) OVER w1 AS lag_passes_accurate_3
,LAG(passes_accurate,4) OVER w1 AS lag_passes_accurate_4
,LAG(passes_perc,1) OVER w1 AS lag_passes_perc_1
,LAG(passes_perc,2) OVER w1 AS lag_passes_perc_2
,LAG(passes_perc,3) OVER w1 AS lag_passes_perc_3
,LAG(passes_perc,4) OVER w1 AS lag_passes_perc_4
,LAG(goals_prevented,1) OVER w1 AS lag_goals_prevented_1
,LAG(goals_prevented,2) OVER w1 AS lag_goals_prevented_2
,LAG(goals_prevented,3) OVER w1 AS lag_goals_prevented_3
,LAG(goals_prevented,4) OVER w1 AS lag_goals_prevented_4
,LAG(card_reviewed,1) OVER w1 AS lag_card_reviewed_1
,LAG(card_reviewed,2) OVER w1 AS lag_card_reviewed_2
,LAG(card_reviewed,3) OVER w1 AS lag_card_reviewed_3
,LAG(card_reviewed,4) OVER w1 AS lag_card_reviewed_4
,LAG(card_upgrade,1) OVER w1 AS lag_card_upgrade_1
,LAG(card_upgrade,2) OVER w1 AS lag_card_upgrade_2
,LAG(card_upgrade,3) OVER w1 AS lag_card_upgrade_3
,LAG(card_upgrade,4) OVER w1 AS lag_card_upgrade_4
,LAG(goal_cancelled,1) OVER w1 AS lag_goal_cancelled_1
,LAG(goal_cancelled,2) OVER w1 AS lag_goal_cancelled_2
,LAG(goal_cancelled,3) OVER w1 AS lag_goal_cancelled_3
,LAG(goal_cancelled,4) OVER w1 AS lag_goal_cancelled_4
,LAG(goal_confirmed,1) OVER w1 AS lag_goal_confirmed_1
,LAG(goal_confirmed,2) OVER w1 AS lag_goal_confirmed_2
,LAG(goal_confirmed,3) OVER w1 AS lag_goal_confirmed_3
,LAG(goal_confirmed,4) OVER w1 AS lag_goal_confirmed_4
,LAG(goal_disallowed,1) OVER w1 AS lag_goal_disallowed_1
,LAG(goal_disallowed,2) OVER w1 AS lag_goal_disallowed_2
,LAG(goal_disallowed,3) OVER w1 AS lag_goal_disallowed_3
,LAG(goal_disallowed,4) OVER w1 AS lag_goal_disallowed_4
,LAG(goal_disallowed_foul,1) OVER w1 AS lag_goal_disallowed_foul_1
,LAG(goal_disallowed_foul,2) OVER w1 AS lag_goal_disallowed_foul_2
,LAG(goal_disallowed_foul,3) OVER w1 AS lag_goal_disallowed_foul_3
,LAG(goal_disallowed_foul,4) OVER w1 AS lag_goal_disallowed_foul_4
,LAG(goal_disallowed_handball,1) OVER w1 AS lag_goal_disallowed_handball_1
,LAG(goal_disallowed_handball,2) OVER w1 AS lag_goal_disallowed_handball_2
,LAG(goal_disallowed_handball,3) OVER w1 AS lag_goal_disallowed_handball_3
,LAG(goal_disallowed_handball,4) OVER w1 AS lag_goal_disallowed_handball_4
,LAG(goal_disallowed_offside,1) OVER w1 AS lag_goal_disallowed_offside_1
,LAG(goal_disallowed_offside,2) OVER w1 AS lag_goal_disallowed_offside_2
,LAG(goal_disallowed_offside,3) OVER w1 AS lag_goal_disallowed_offside_3
,LAG(goal_disallowed_offside,4) OVER w1 AS lag_goal_disallowed_offside_4
,LAG(missed_penalty,1) OVER w1 AS lag_missed_penalty_1
,LAG(missed_penalty,2) OVER w1 AS lag_missed_penalty_2
,LAG(missed_penalty,3) OVER w1 AS lag_missed_penalty_3
,LAG(missed_penalty,4) OVER w1 AS lag_missed_penalty_4
,LAG(normal_goal,1) OVER w1 AS lag_normal_goal_1
,LAG(normal_goal,2) OVER w1 AS lag_normal_goal_2
,LAG(normal_goal,3) OVER w1 AS lag_normal_goal_3
,LAG(normal_goal,4) OVER w1 AS lag_normal_goal_4
,LAG(own_goal,1) OVER w1 AS lag_own_goal_1
,LAG(own_goal,2) OVER w1 AS lag_own_goal_2
,LAG(own_goal,3) OVER w1 AS lag_own_goal_3
,LAG(own_goal,4) OVER w1 AS lag_own_goal_4
,LAG(penalty,1) OVER w1 AS lag_penalty_1
,LAG(penalty,2) OVER w1 AS lag_penalty_2
,LAG(penalty,3) OVER w1 AS lag_penalty_3
,LAG(penalty,4) OVER w1 AS lag_penalty_4
,LAG(penalty_awarded,1) OVER w1 AS lag_penalty_awarded_1
,LAG(penalty_awarded,2) OVER w1 AS lag_penalty_awarded_2
,LAG(penalty_awarded,3) OVER w1 AS lag_penalty_awarded_3
,LAG(penalty_awarded,4) OVER w1 AS lag_penalty_awarded_4
,LAG(penalty_cancelled,1) OVER w1 AS lag_penalty_cancelled_1
,LAG(penalty_cancelled,2) OVER w1 AS lag_penalty_cancelled_2
,LAG(penalty_cancelled,3) OVER w1 AS lag_penalty_cancelled_3
,LAG(penalty_cancelled,4) OVER w1 AS lag_penalty_cancelled_4
,LAG(penalty_confirmed,1) OVER w1 AS lag_penalty_confirmed_1
,LAG(penalty_confirmed,2) OVER w1 AS lag_penalty_confirmed_2
,LAG(penalty_confirmed,3) OVER w1 AS lag_penalty_confirmed_3
,LAG(penalty_confirmed,4) OVER w1 AS lag_penalty_confirmed_4
,LAG(red_card,1) OVER w1 AS lag_red_card_1
,LAG(red_card,2) OVER w1 AS lag_red_card_2
,LAG(red_card,3) OVER w1 AS lag_red_card_3
,LAG(red_card,4) OVER w1 AS lag_red_card_4
,LAG(red_card_cancelled,1) OVER w1 AS lag_red_card_cancelled_1
,LAG(red_card_cancelled,2) OVER w1 AS lag_red_card_cancelled_2
,LAG(red_card_cancelled,3) OVER w1 AS lag_red_card_cancelled_3
,LAG(red_card_cancelled,4) OVER w1 AS lag_red_card_cancelled_4
,LAG(substitution_1,1) OVER w1 AS lag_substitution_1_1
,LAG(substitution_1,2) OVER w1 AS lag_substitution_1_2
,LAG(substitution_1,3) OVER w1 AS lag_substitution_1_3
,LAG(substitution_1,4) OVER w1 AS lag_substitution_1_4
,LAG(substitution_10,1) OVER w1 AS lag_substitution_10_1
,LAG(substitution_10,2) OVER w1 AS lag_substitution_10_2
,LAG(substitution_10,3) OVER w1 AS lag_substitution_10_3
,LAG(substitution_10,4) OVER w1 AS lag_substitution_10_4
,LAG(substitution_11,1) OVER w1 AS lag_substitution_11_1
,LAG(substitution_11,2) OVER w1 AS lag_substitution_11_2
,LAG(substitution_11,3) OVER w1 AS lag_substitution_11_3
,LAG(substitution_11,4) OVER w1 AS lag_substitution_11_4
,LAG(substitution_12,1) OVER w1 AS lag_substitution_12_1
,LAG(substitution_12,2) OVER w1 AS lag_substitution_12_2
,LAG(substitution_12,3) OVER w1 AS lag_substitution_12_3
,LAG(substitution_12,4) OVER w1 AS lag_substitution_12_4
,LAG(substitution_13,1) OVER w1 AS lag_substitution_13_1
,LAG(substitution_13,2) OVER w1 AS lag_substitution_13_2
,LAG(substitution_13,3) OVER w1 AS lag_substitution_13_3
,LAG(substitution_13,4) OVER w1 AS lag_substitution_13_4
,LAG(substitution_14,1) OVER w1 AS lag_substitution_14_1
,LAG(substitution_14,2) OVER w1 AS lag_substitution_14_2
,LAG(substitution_14,3) OVER w1 AS lag_substitution_14_3
,LAG(substitution_14,4) OVER w1 AS lag_substitution_14_4
,LAG(substitution_15,1) OVER w1 AS lag_substitution_15_1
,LAG(substitution_15,2) OVER w1 AS lag_substitution_15_2
,LAG(substitution_15,3) OVER w1 AS lag_substitution_15_3
,LAG(substitution_15,4) OVER w1 AS lag_substitution_15_4
,LAG(substitution_16,1) OVER w1 AS lag_substitution_16_1
,LAG(substitution_16,2) OVER w1 AS lag_substitution_16_2
,LAG(substitution_16,3) OVER w1 AS lag_substitution_16_3
,LAG(substitution_16,4) OVER w1 AS lag_substitution_16_4
,LAG(substitution_17,1) OVER w1 AS lag_substitution_17_1
,LAG(substitution_17,2) OVER w1 AS lag_substitution_17_2
,LAG(substitution_17,3) OVER w1 AS lag_substitution_17_3
,LAG(substitution_17,4) OVER w1 AS lag_substitution_17_4
,LAG(substitution_18,1) OVER w1 AS lag_substitution_18_1
,LAG(substitution_18,2) OVER w1 AS lag_substitution_18_2
,LAG(substitution_18,3) OVER w1 AS lag_substitution_18_3
,LAG(substitution_18,4) OVER w1 AS lag_substitution_18_4
,LAG(substitution_2,1) OVER w1 AS lag_substitution_2_1
,LAG(substitution_2,2) OVER w1 AS lag_substitution_2_2
,LAG(substitution_2,3) OVER w1 AS lag_substitution_2_3
,LAG(substitution_2,4) OVER w1 AS lag_substitution_2_4
,LAG(substitution_3,1) OVER w1 AS lag_substitution_3_1
,LAG(substitution_3,2) OVER w1 AS lag_substitution_3_2
,LAG(substitution_3,3) OVER w1 AS lag_substitution_3_3
,LAG(substitution_3,4) OVER w1 AS lag_substitution_3_4
,LAG(substitution_4,1) OVER w1 AS lag_substitution_4_1
,LAG(substitution_4,2) OVER w1 AS lag_substitution_4_2
,LAG(substitution_4,3) OVER w1 AS lag_substitution_4_3
,LAG(substitution_4,4) OVER w1 AS lag_substitution_4_4
,LAG(substitution_5,1) OVER w1 AS lag_substitution_5_1
,LAG(substitution_5,2) OVER w1 AS lag_substitution_5_2
,LAG(substitution_5,3) OVER w1 AS lag_substitution_5_3
,LAG(substitution_5,4) OVER w1 AS lag_substitution_5_4
,LAG(substitution_6,1) OVER w1 AS lag_substitution_6_1
,LAG(substitution_6,2) OVER w1 AS lag_substitution_6_2
,LAG(substitution_6,3) OVER w1 AS lag_substitution_6_3
,LAG(substitution_6,4) OVER w1 AS lag_substitution_6_4
,LAG(substitution_7,1) OVER w1 AS lag_substitution_7_1
,LAG(substitution_7,2) OVER w1 AS lag_substitution_7_2
,LAG(substitution_7,3) OVER w1 AS lag_substitution_7_3
,LAG(substitution_7,4) OVER w1 AS lag_substitution_7_4
,LAG(substitution_8,1) OVER w1 AS lag_substitution_8_1
,LAG(substitution_8,2) OVER w1 AS lag_substitution_8_2
,LAG(substitution_8,3) OVER w1 AS lag_substitution_8_3
,LAG(substitution_8,4) OVER w1 AS lag_substitution_8_4
,LAG(substitution_9,1) OVER w1 AS lag_substitution_9_1
,LAG(substitution_9,2) OVER w1 AS lag_substitution_9_2
,LAG(substitution_9,3) OVER w1 AS lag_substitution_9_3
,LAG(substitution_9,4) OVER w1 AS lag_substitution_9_4
,LAG(yellow_card,1) OVER w1 AS lag_yellow_card_1
,LAG(yellow_card,2) OVER w1 AS lag_yellow_card_2
,LAG(yellow_card,3) OVER w1 AS lag_yellow_card_3
,LAG(yellow_card,4) OVER w1 AS lag_yellow_card_4
,LAG(games_minutes,1) OVER w1 AS lag_games_minutes_1
,LAG(games_minutes,2) OVER w1 AS lag_games_minutes_2
,LAG(games_minutes,3) OVER w1 AS lag_games_minutes_3
,LAG(games_minutes,4) OVER w1 AS lag_games_minutes_4
,LAG(shots_total,1) OVER w1 AS lag_shots_total_1
,LAG(shots_total,2) OVER w1 AS lag_shots_total_2
,LAG(shots_total,3) OVER w1 AS lag_shots_total_3
,LAG(shots_total,4) OVER w1 AS lag_shots_total_4
,LAG(shots_on,1) OVER w1 AS lag_shots_on_1
,LAG(shots_on,2) OVER w1 AS lag_shots_on_2
,LAG(shots_on,3) OVER w1 AS lag_shots_on_3
,LAG(shots_on,4) OVER w1 AS lag_shots_on_4
,LAG(goals_total,1) OVER w1 AS lag_goals_total_1
,LAG(goals_total,2) OVER w1 AS lag_goals_total_2
,LAG(goals_total,3) OVER w1 AS lag_goals_total_3
,LAG(goals_total,4) OVER w1 AS lag_goals_total_4
,LAG(goals_conceded,1) OVER w1 AS lag_goals_conceded_1
,LAG(goals_conceded,2) OVER w1 AS lag_goals_conceded_2
,LAG(goals_conceded,3) OVER w1 AS lag_goals_conceded_3
,LAG(goals_conceded,4) OVER w1 AS lag_goals_conceded_4
,LAG(goals_assists,1) OVER w1 AS lag_goals_assists_1
,LAG(goals_assists,2) OVER w1 AS lag_goals_assists_2
,LAG(goals_assists,3) OVER w1 AS lag_goals_assists_3
,LAG(goals_assists,4) OVER w1 AS lag_goals_assists_4
,LAG(goals_saves,1) OVER w1 AS lag_goals_saves_1
,LAG(goals_saves,2) OVER w1 AS lag_goals_saves_2
,LAG(goals_saves,3) OVER w1 AS lag_goals_saves_3
,LAG(goals_saves,4) OVER w1 AS lag_goals_saves_4
,LAG(passes_total,1) OVER w1 AS lag_passes_total_1
,LAG(passes_total,2) OVER w1 AS lag_passes_total_2
,LAG(passes_total,3) OVER w1 AS lag_passes_total_3
,LAG(passes_total,4) OVER w1 AS lag_passes_total_4
,LAG(passes_key,1) OVER w1 AS lag_passes_key_1
,LAG(passes_key,2) OVER w1 AS lag_passes_key_2
,LAG(passes_key,3) OVER w1 AS lag_passes_key_3
,LAG(passes_key,4) OVER w1 AS lag_passes_key_4
,LAG(passes_accuracy,1) OVER w1 AS lag_passes_accuracy_1
,LAG(passes_accuracy,2) OVER w1 AS lag_passes_accuracy_2
,LAG(passes_accuracy,3) OVER w1 AS lag_passes_accuracy_3
,LAG(passes_accuracy,4) OVER w1 AS lag_passes_accuracy_4
,LAG(tackles_total,1) OVER w1 AS lag_tackles_total_1
,LAG(tackles_total,2) OVER w1 AS lag_tackles_total_2
,LAG(tackles_total,3) OVER w1 AS lag_tackles_total_3
,LAG(tackles_total,4) OVER w1 AS lag_tackles_total_4
,LAG(tackles_blocks,1) OVER w1 AS lag_tackles_blocks_1
,LAG(tackles_blocks,2) OVER w1 AS lag_tackles_blocks_2
,LAG(tackles_blocks,3) OVER w1 AS lag_tackles_blocks_3
,LAG(tackles_blocks,4) OVER w1 AS lag_tackles_blocks_4
,LAG(tackles_interceptions,1) OVER w1 AS lag_tackles_interceptions_1
,LAG(tackles_interceptions,2) OVER w1 AS lag_tackles_interceptions_2
,LAG(tackles_interceptions,3) OVER w1 AS lag_tackles_interceptions_3
,LAG(tackles_interceptions,4) OVER w1 AS lag_tackles_interceptions_4
,LAG(duels_total,1) OVER w1 AS lag_duels_total_1
,LAG(duels_total,2) OVER w1 AS lag_duels_total_2
,LAG(duels_total,3) OVER w1 AS lag_duels_total_3
,LAG(duels_total,4) OVER w1 AS lag_duels_total_4
,LAG(duels_won,1) OVER w1 AS lag_duels_won_1
,LAG(duels_won,2) OVER w1 AS lag_duels_won_2
,LAG(duels_won,3) OVER w1 AS lag_duels_won_3
,LAG(duels_won,4) OVER w1 AS lag_duels_won_4
,LAG(dribbles_attempts,1) OVER w1 AS lag_dribbles_attempts_1
,LAG(dribbles_attempts,2) OVER w1 AS lag_dribbles_attempts_2
,LAG(dribbles_attempts,3) OVER w1 AS lag_dribbles_attempts_3
,LAG(dribbles_attempts,4) OVER w1 AS lag_dribbles_attempts_4
,LAG(dribbles_success,1) OVER w1 AS lag_dribbles_success_1
,LAG(dribbles_success,2) OVER w1 AS lag_dribbles_success_2
,LAG(dribbles_success,3) OVER w1 AS lag_dribbles_success_3
,LAG(dribbles_success,4) OVER w1 AS lag_dribbles_success_4
,LAG(dribbles_past,1) OVER w1 AS lag_dribbles_past_1
,LAG(dribbles_past,2) OVER w1 AS lag_dribbles_past_2
,LAG(dribbles_past,3) OVER w1 AS lag_dribbles_past_3
,LAG(dribbles_past,4) OVER w1 AS lag_dribbles_past_4
,LAG(fouls_drawn,1) OVER w1 AS lag_fouls_drawn_1
,LAG(fouls_drawn,2) OVER w1 AS lag_fouls_drawn_2
,LAG(fouls_drawn,3) OVER w1 AS lag_fouls_drawn_3
,LAG(fouls_drawn,4) OVER w1 AS lag_fouls_drawn_4
,LAG(fouls_committed,1) OVER w1 AS lag_fouls_committed_1
,LAG(fouls_committed,2) OVER w1 AS lag_fouls_committed_2
,LAG(fouls_committed,3) OVER w1 AS lag_fouls_committed_3
,LAG(fouls_committed,4) OVER w1 AS lag_fouls_committed_4
,LAG(cards_yellow,1) OVER w1 AS lag_cards_yellow_1
,LAG(cards_yellow,2) OVER w1 AS lag_cards_yellow_2
,LAG(cards_yellow,3) OVER w1 AS lag_cards_yellow_3
,LAG(cards_yellow,4) OVER w1 AS lag_cards_yellow_4
,LAG(cards_red,1) OVER w1 AS lag_cards_red_1
,LAG(cards_red,2) OVER w1 AS lag_cards_red_2
,LAG(cards_red,3) OVER w1 AS lag_cards_red_3
,LAG(cards_red,4) OVER w1 AS lag_cards_red_4
,LAG(penalty_won,1) OVER w1 AS lag_penalty_won_1
,LAG(penalty_won,2) OVER w1 AS lag_penalty_won_2
,LAG(penalty_won,3) OVER w1 AS lag_penalty_won_3
,LAG(penalty_won,4) OVER w1 AS lag_penalty_won_4
,LAG(penalty_commited,1) OVER w1 AS lag_penalty_commited_1
,LAG(penalty_commited,2) OVER w1 AS lag_penalty_commited_2
,LAG(penalty_commited,3) OVER w1 AS lag_penalty_commited_3
,LAG(penalty_commited,4) OVER w1 AS lag_penalty_commited_4
,LAG(penalty_scored,1) OVER w1 AS lag_penalty_scored_1
,LAG(penalty_scored,2) OVER w1 AS lag_penalty_scored_2
,LAG(penalty_scored,3) OVER w1 AS lag_penalty_scored_3
,LAG(penalty_scored,4) OVER w1 AS lag_penalty_scored_4
,LAG(penalty_missed,1) OVER w1 AS lag_penalty_missed_1
,LAG(penalty_missed,2) OVER w1 AS lag_penalty_missed_2
,LAG(penalty_missed,3) OVER w1 AS lag_penalty_missed_3
,LAG(penalty_missed,4) OVER w1 AS lag_penalty_missed_4
,LAG(penalty_saved,1) OVER w1 AS lag_penalty_saved_1
,LAG(penalty_saved,2) OVER w1 AS lag_penalty_saved_2
,LAG(penalty_saved,3) OVER w1 AS lag_penalty_saved_3
,LAG(penalty_saved,4) OVER w1 AS lag_penalty_saved_4
FROM
transformed_prod_match_summary t1
WINDOW
        w1 AS (PARTITION BY team_id ORDER BY date, fixture_id)
)
SELECT t1.*
FROM lagged_data t1;


-- Tendencies
DROP TABLE IF EXISTS transformed_prod_match_summary_tendencies;
CREATE TEMP TABLE transformed_prod_match_summary_tendencies AS
WITH numbered_matches AS (
    SELECT
        t1.*,
        ROW_NUMBER() OVER (
            PARTITION BY team_id
            ORDER BY date, fixture_id
        )::real AS match_number
    FROM transformed_prod_match_summary t1
),
metrics AS (
    SELECT
        fixture_id
        ,date
        ,venue_id
        ,venue_name
        ,status_elapsed
        ,status_extra
        ,league_id
        ,team_id
        ,goals
        ,is_winner
        ,is_home
        ,league_season
        ,CASE WHEN COUNT(shots_on_goal) OVER w3 = 4 THEN -REGR_SLOPE(shots_on_goal::real, match_number) OVER w3 END AS shots_on_goal_slope_3
        ,CASE WHEN COUNT(shots_on_goal) OVER w6 = 7 THEN -REGR_SLOPE(shots_on_goal::real, match_number) OVER w6 END AS shots_on_goal_slope_6
        ,CASE WHEN COUNT(shots_off_goal) OVER w3 = 4 THEN -REGR_SLOPE(shots_off_goal::real, match_number) OVER w3 END AS shots_off_goal_slope_3
        ,CASE WHEN COUNT(shots_off_goal) OVER w6 = 7 THEN -REGR_SLOPE(shots_off_goal::real, match_number) OVER w6 END AS shots_off_goal_slope_6
        ,CASE WHEN COUNT(total_shots) OVER w3 = 4 THEN -REGR_SLOPE(total_shots::real, match_number) OVER w3 END AS total_shots_slope_3
        ,CASE WHEN COUNT(total_shots) OVER w6 = 7 THEN -REGR_SLOPE(total_shots::real, match_number) OVER w6 END AS total_shots_slope_6
        ,CASE WHEN COUNT(blocked_shots) OVER w3 = 4 THEN -REGR_SLOPE(blocked_shots::real, match_number) OVER w3 END AS blocked_shots_slope_3
        ,CASE WHEN COUNT(blocked_shots) OVER w6 = 7 THEN -REGR_SLOPE(blocked_shots::real, match_number) OVER w6 END AS blocked_shots_slope_6
        ,CASE WHEN COUNT(shots_insidebox) OVER w3 = 4 THEN -REGR_SLOPE(shots_insidebox::real, match_number) OVER w3 END AS shots_insidebox_slope_3
        ,CASE WHEN COUNT(shots_insidebox) OVER w6 = 7 THEN -REGR_SLOPE(shots_insidebox::real, match_number) OVER w6 END AS shots_insidebox_slope_6
        ,CASE WHEN COUNT(shots_outsidebox) OVER w3 = 4 THEN -REGR_SLOPE(shots_outsidebox::real, match_number) OVER w3 END AS shots_outsidebox_slope_3
        ,CASE WHEN COUNT(shots_outsidebox) OVER w6 = 7 THEN -REGR_SLOPE(shots_outsidebox::real, match_number) OVER w6 END AS shots_outsidebox_slope_6
        ,CASE WHEN COUNT(fouls) OVER w3 = 4 THEN -REGR_SLOPE(fouls::real, match_number) OVER w3 END AS fouls_slope_3
        ,CASE WHEN COUNT(fouls) OVER w6 = 7 THEN -REGR_SLOPE(fouls::real, match_number) OVER w6 END AS fouls_slope_6
        ,CASE WHEN COUNT(corner_kicks) OVER w3 = 4 THEN -REGR_SLOPE(corner_kicks::real, match_number) OVER w3 END AS corner_kicks_slope_3
        ,CASE WHEN COUNT(corner_kicks) OVER w6 = 7 THEN -REGR_SLOPE(corner_kicks::real, match_number) OVER w6 END AS corner_kicks_slope_6
        ,CASE WHEN COUNT(offsides) OVER w3 = 4 THEN -REGR_SLOPE(offsides::real, match_number) OVER w3 END AS offsides_slope_3
        ,CASE WHEN COUNT(offsides) OVER w6 = 7 THEN -REGR_SLOPE(offsides::real, match_number) OVER w6 END AS offsides_slope_6
        ,CASE WHEN COUNT(ball_possession) OVER w3 = 4 THEN -REGR_SLOPE(ball_possession::real, match_number) OVER w3 END AS ball_possession_slope_3
        ,CASE WHEN COUNT(ball_possession) OVER w6 = 7 THEN -REGR_SLOPE(ball_possession::real, match_number) OVER w6 END AS ball_possession_slope_6
        ,CASE WHEN COUNT(yellow_cards) OVER w3 = 4 THEN -REGR_SLOPE(yellow_cards::real, match_number) OVER w3 END AS yellow_cards_slope_3
        ,CASE WHEN COUNT(yellow_cards) OVER w6 = 7 THEN -REGR_SLOPE(yellow_cards::real, match_number) OVER w6 END AS yellow_cards_slope_6
        ,CASE WHEN COUNT(red_cards) OVER w3 = 4 THEN -REGR_SLOPE(red_cards::real, match_number) OVER w3 END AS red_cards_slope_3
        ,CASE WHEN COUNT(red_cards) OVER w6 = 7 THEN -REGR_SLOPE(red_cards::real, match_number) OVER w6 END AS red_cards_slope_6
        ,CASE WHEN COUNT(goalkeeper_saves) OVER w3 = 4 THEN -REGR_SLOPE(goalkeeper_saves::real, match_number) OVER w3 END AS goalkeeper_saves_slope_3
        ,CASE WHEN COUNT(goalkeeper_saves) OVER w6 = 7 THEN -REGR_SLOPE(goalkeeper_saves::real, match_number) OVER w6 END AS goalkeeper_saves_slope_6
        ,CASE WHEN COUNT(total_passes) OVER w3 = 4 THEN -REGR_SLOPE(total_passes::real, match_number) OVER w3 END AS total_passes_slope_3
        ,CASE WHEN COUNT(total_passes) OVER w6 = 7 THEN -REGR_SLOPE(total_passes::real, match_number) OVER w6 END AS total_passes_slope_6
        ,CASE WHEN COUNT(passes_accurate) OVER w3 = 4 THEN -REGR_SLOPE(passes_accurate::real, match_number) OVER w3 END AS passes_accurate_slope_3
        ,CASE WHEN COUNT(passes_accurate) OVER w6 = 7 THEN -REGR_SLOPE(passes_accurate::real, match_number) OVER w6 END AS passes_accurate_slope_6
        ,CASE WHEN COUNT(passes_perc) OVER w3 = 4 THEN -REGR_SLOPE(passes_perc::real, match_number) OVER w3 END AS passes_perc_slope_3
        ,CASE WHEN COUNT(passes_perc) OVER w6 = 7 THEN -REGR_SLOPE(passes_perc::real, match_number) OVER w6 END AS passes_perc_slope_6
        ,CASE WHEN COUNT(goals_prevented) OVER w3 = 4 THEN -REGR_SLOPE(goals_prevented::real, match_number) OVER w3 END AS goals_prevented_slope_3
        ,CASE WHEN COUNT(goals_prevented) OVER w6 = 7 THEN -REGR_SLOPE(goals_prevented::real, match_number) OVER w6 END AS goals_prevented_slope_6
        ,CASE WHEN COUNT(card_reviewed) OVER w3 = 4 THEN -REGR_SLOPE(card_reviewed::real, match_number) OVER w3 END AS card_reviewed_slope_3
        ,CASE WHEN COUNT(card_reviewed) OVER w6 = 7 THEN -REGR_SLOPE(card_reviewed::real, match_number) OVER w6 END AS card_reviewed_slope_6
        ,CASE WHEN COUNT(card_upgrade) OVER w3 = 4 THEN -REGR_SLOPE(card_upgrade::real, match_number) OVER w3 END AS card_upgrade_slope_3
        ,CASE WHEN COUNT(card_upgrade) OVER w6 = 7 THEN -REGR_SLOPE(card_upgrade::real, match_number) OVER w6 END AS card_upgrade_slope_6
        ,CASE WHEN COUNT(goal_cancelled) OVER w3 = 4 THEN -REGR_SLOPE(goal_cancelled::real, match_number) OVER w3 END AS goal_cancelled_slope_3
        ,CASE WHEN COUNT(goal_cancelled) OVER w6 = 7 THEN -REGR_SLOPE(goal_cancelled::real, match_number) OVER w6 END AS goal_cancelled_slope_6
        ,CASE WHEN COUNT(goal_confirmed) OVER w3 = 4 THEN -REGR_SLOPE(goal_confirmed::real, match_number) OVER w3 END AS goal_confirmed_slope_3
        ,CASE WHEN COUNT(goal_confirmed) OVER w6 = 7 THEN -REGR_SLOPE(goal_confirmed::real, match_number) OVER w6 END AS goal_confirmed_slope_6
        ,CASE WHEN COUNT(goal_disallowed) OVER w3 = 4 THEN -REGR_SLOPE(goal_disallowed::real, match_number) OVER w3 END AS goal_disallowed_slope_3
        ,CASE WHEN COUNT(goal_disallowed) OVER w6 = 7 THEN -REGR_SLOPE(goal_disallowed::real, match_number) OVER w6 END AS goal_disallowed_slope_6
        ,CASE WHEN COUNT(goal_disallowed_foul) OVER w3 = 4 THEN -REGR_SLOPE(goal_disallowed_foul::real, match_number) OVER w3 END AS goal_disallowed_foul_slope_3
        ,CASE WHEN COUNT(goal_disallowed_foul) OVER w6 = 7 THEN -REGR_SLOPE(goal_disallowed_foul::real, match_number) OVER w6 END AS goal_disallowed_foul_slope_6
        ,CASE WHEN COUNT(goal_disallowed_handball) OVER w3 = 4 THEN -REGR_SLOPE(goal_disallowed_handball::real, match_number) OVER w3 END AS goal_disallowed_handball_slope_3
        ,CASE WHEN COUNT(goal_disallowed_handball) OVER w6 = 7 THEN -REGR_SLOPE(goal_disallowed_handball::real, match_number) OVER w6 END AS goal_disallowed_handball_slope_6
        ,CASE WHEN COUNT(goal_disallowed_offside) OVER w3 = 4 THEN -REGR_SLOPE(goal_disallowed_offside::real, match_number) OVER w3 END AS goal_disallowed_offside_slope_3
        ,CASE WHEN COUNT(goal_disallowed_offside) OVER w6 = 7 THEN -REGR_SLOPE(goal_disallowed_offside::real, match_number) OVER w6 END AS goal_disallowed_offside_slope_6
        ,CASE WHEN COUNT(missed_penalty) OVER w3 = 4 THEN -REGR_SLOPE(missed_penalty::real, match_number) OVER w3 END AS missed_penalty_slope_3
        ,CASE WHEN COUNT(missed_penalty) OVER w6 = 7 THEN -REGR_SLOPE(missed_penalty::real, match_number) OVER w6 END AS missed_penalty_slope_6
        ,CASE WHEN COUNT(normal_goal) OVER w3 = 4 THEN -REGR_SLOPE(normal_goal::real, match_number) OVER w3 END AS normal_goal_slope_3
        ,CASE WHEN COUNT(normal_goal) OVER w6 = 7 THEN -REGR_SLOPE(normal_goal::real, match_number) OVER w6 END AS normal_goal_slope_6
        ,CASE WHEN COUNT(own_goal) OVER w3 = 4 THEN -REGR_SLOPE(own_goal::real, match_number) OVER w3 END AS own_goal_slope_3
        ,CASE WHEN COUNT(own_goal) OVER w6 = 7 THEN -REGR_SLOPE(own_goal::real, match_number) OVER w6 END AS own_goal_slope_6
        ,CASE WHEN COUNT(penalty) OVER w3 = 4 THEN -REGR_SLOPE(penalty::real, match_number) OVER w3 END AS penalty_slope_3
        ,CASE WHEN COUNT(penalty) OVER w6 = 7 THEN -REGR_SLOPE(penalty::real, match_number) OVER w6 END AS penalty_slope_6
        ,CASE WHEN COUNT(penalty_awarded) OVER w3 = 4 THEN -REGR_SLOPE(penalty_awarded::real, match_number) OVER w3 END AS penalty_awarded_slope_3
        ,CASE WHEN COUNT(penalty_awarded) OVER w6 = 7 THEN -REGR_SLOPE(penalty_awarded::real, match_number) OVER w6 END AS penalty_awarded_slope_6
        ,CASE WHEN COUNT(penalty_cancelled) OVER w3 = 4 THEN -REGR_SLOPE(penalty_cancelled::real, match_number) OVER w3 END AS penalty_cancelled_slope_3
        ,CASE WHEN COUNT(penalty_cancelled) OVER w6 = 7 THEN -REGR_SLOPE(penalty_cancelled::real, match_number) OVER w6 END AS penalty_cancelled_slope_6
        ,CASE WHEN COUNT(penalty_confirmed) OVER w3 = 4 THEN -REGR_SLOPE(penalty_confirmed::real, match_number) OVER w3 END AS penalty_confirmed_slope_3
        ,CASE WHEN COUNT(penalty_confirmed) OVER w6 = 7 THEN -REGR_SLOPE(penalty_confirmed::real, match_number) OVER w6 END AS penalty_confirmed_slope_6
        ,CASE WHEN COUNT(red_card) OVER w3 = 4 THEN -REGR_SLOPE(red_card::real, match_number) OVER w3 END AS red_card_slope_3
        ,CASE WHEN COUNT(red_card) OVER w6 = 7 THEN -REGR_SLOPE(red_card::real, match_number) OVER w6 END AS red_card_slope_6
        ,CASE WHEN COUNT(red_card_cancelled) OVER w3 = 4 THEN -REGR_SLOPE(red_card_cancelled::real, match_number) OVER w3 END AS red_card_cancelled_slope_3
        ,CASE WHEN COUNT(red_card_cancelled) OVER w6 = 7 THEN -REGR_SLOPE(red_card_cancelled::real, match_number) OVER w6 END AS red_card_cancelled_slope_6
        ,CASE WHEN COUNT(substitution_1) OVER w3 = 4 THEN -REGR_SLOPE(substitution_1::real, match_number) OVER w3 END AS substitution_1_slope_3
        ,CASE WHEN COUNT(substitution_1) OVER w6 = 7 THEN -REGR_SLOPE(substitution_1::real, match_number) OVER w6 END AS substitution_1_slope_6
        ,CASE WHEN COUNT(substitution_10) OVER w3 = 4 THEN -REGR_SLOPE(substitution_10::real, match_number) OVER w3 END AS substitution_10_slope_3
        ,CASE WHEN COUNT(substitution_10) OVER w6 = 7 THEN -REGR_SLOPE(substitution_10::real, match_number) OVER w6 END AS substitution_10_slope_6
        ,CASE WHEN COUNT(substitution_11) OVER w3 = 4 THEN -REGR_SLOPE(substitution_11::real, match_number) OVER w3 END AS substitution_11_slope_3
        ,CASE WHEN COUNT(substitution_11) OVER w6 = 7 THEN -REGR_SLOPE(substitution_11::real, match_number) OVER w6 END AS substitution_11_slope_6
        ,CASE WHEN COUNT(substitution_12) OVER w3 = 4 THEN -REGR_SLOPE(substitution_12::real, match_number) OVER w3 END AS substitution_12_slope_3
        ,CASE WHEN COUNT(substitution_12) OVER w6 = 7 THEN -REGR_SLOPE(substitution_12::real, match_number) OVER w6 END AS substitution_12_slope_6
        ,CASE WHEN COUNT(substitution_13) OVER w3 = 4 THEN -REGR_SLOPE(substitution_13::real, match_number) OVER w3 END AS substitution_13_slope_3
        ,CASE WHEN COUNT(substitution_13) OVER w6 = 7 THEN -REGR_SLOPE(substitution_13::real, match_number) OVER w6 END AS substitution_13_slope_6
        ,CASE WHEN COUNT(substitution_14) OVER w3 = 4 THEN -REGR_SLOPE(substitution_14::real, match_number) OVER w3 END AS substitution_14_slope_3
        ,CASE WHEN COUNT(substitution_14) OVER w6 = 7 THEN -REGR_SLOPE(substitution_14::real, match_number) OVER w6 END AS substitution_14_slope_6
        ,CASE WHEN COUNT(substitution_15) OVER w3 = 4 THEN -REGR_SLOPE(substitution_15::real, match_number) OVER w3 END AS substitution_15_slope_3
        ,CASE WHEN COUNT(substitution_15) OVER w6 = 7 THEN -REGR_SLOPE(substitution_15::real, match_number) OVER w6 END AS substitution_15_slope_6
        ,CASE WHEN COUNT(substitution_16) OVER w3 = 4 THEN -REGR_SLOPE(substitution_16::real, match_number) OVER w3 END AS substitution_16_slope_3
        ,CASE WHEN COUNT(substitution_16) OVER w6 = 7 THEN -REGR_SLOPE(substitution_16::real, match_number) OVER w6 END AS substitution_16_slope_6
        ,CASE WHEN COUNT(substitution_17) OVER w3 = 4 THEN -REGR_SLOPE(substitution_17::real, match_number) OVER w3 END AS substitution_17_slope_3
        ,CASE WHEN COUNT(substitution_17) OVER w6 = 7 THEN -REGR_SLOPE(substitution_17::real, match_number) OVER w6 END AS substitution_17_slope_6
        ,CASE WHEN COUNT(substitution_18) OVER w3 = 4 THEN -REGR_SLOPE(substitution_18::real, match_number) OVER w3 END AS substitution_18_slope_3
        ,CASE WHEN COUNT(substitution_18) OVER w6 = 7 THEN -REGR_SLOPE(substitution_18::real, match_number) OVER w6 END AS substitution_18_slope_6
        ,CASE WHEN COUNT(substitution_2) OVER w3 = 4 THEN -REGR_SLOPE(substitution_2::real, match_number) OVER w3 END AS substitution_2_slope_3
        ,CASE WHEN COUNT(substitution_2) OVER w6 = 7 THEN -REGR_SLOPE(substitution_2::real, match_number) OVER w6 END AS substitution_2_slope_6
        ,CASE WHEN COUNT(substitution_3) OVER w3 = 4 THEN -REGR_SLOPE(substitution_3::real, match_number) OVER w3 END AS substitution_3_slope_3
        ,CASE WHEN COUNT(substitution_3) OVER w6 = 7 THEN -REGR_SLOPE(substitution_3::real, match_number) OVER w6 END AS substitution_3_slope_6
        ,CASE WHEN COUNT(substitution_4) OVER w3 = 4 THEN -REGR_SLOPE(substitution_4::real, match_number) OVER w3 END AS substitution_4_slope_3
        ,CASE WHEN COUNT(substitution_4) OVER w6 = 7 THEN -REGR_SLOPE(substitution_4::real, match_number) OVER w6 END AS substitution_4_slope_6
        ,CASE WHEN COUNT(substitution_5) OVER w3 = 4 THEN -REGR_SLOPE(substitution_5::real, match_number) OVER w3 END AS substitution_5_slope_3
        ,CASE WHEN COUNT(substitution_5) OVER w6 = 7 THEN -REGR_SLOPE(substitution_5::real, match_number) OVER w6 END AS substitution_5_slope_6
        ,CASE WHEN COUNT(substitution_6) OVER w3 = 4 THEN -REGR_SLOPE(substitution_6::real, match_number) OVER w3 END AS substitution_6_slope_3
        ,CASE WHEN COUNT(substitution_6) OVER w6 = 7 THEN -REGR_SLOPE(substitution_6::real, match_number) OVER w6 END AS substitution_6_slope_6
        ,CASE WHEN COUNT(substitution_7) OVER w3 = 4 THEN -REGR_SLOPE(substitution_7::real, match_number) OVER w3 END AS substitution_7_slope_3
        ,CASE WHEN COUNT(substitution_7) OVER w6 = 7 THEN -REGR_SLOPE(substitution_7::real, match_number) OVER w6 END AS substitution_7_slope_6
        ,CASE WHEN COUNT(substitution_8) OVER w3 = 4 THEN -REGR_SLOPE(substitution_8::real, match_number) OVER w3 END AS substitution_8_slope_3
        ,CASE WHEN COUNT(substitution_8) OVER w6 = 7 THEN -REGR_SLOPE(substitution_8::real, match_number) OVER w6 END AS substitution_8_slope_6
        ,CASE WHEN COUNT(substitution_9) OVER w3 = 4 THEN -REGR_SLOPE(substitution_9::real, match_number) OVER w3 END AS substitution_9_slope_3
        ,CASE WHEN COUNT(substitution_9) OVER w6 = 7 THEN -REGR_SLOPE(substitution_9::real, match_number) OVER w6 END AS substitution_9_slope_6
        ,CASE WHEN COUNT(yellow_card) OVER w3 = 4 THEN -REGR_SLOPE(yellow_card::real, match_number) OVER w3 END AS yellow_card_slope_3
        ,CASE WHEN COUNT(yellow_card) OVER w6 = 7 THEN -REGR_SLOPE(yellow_card::real, match_number) OVER w6 END AS yellow_card_slope_6
        ,CASE WHEN COUNT(games_minutes) OVER w3 = 4 THEN -REGR_SLOPE(games_minutes::real, match_number) OVER w3 END AS games_minutes_slope_3
        ,CASE WHEN COUNT(games_minutes) OVER w6 = 7 THEN -REGR_SLOPE(games_minutes::real, match_number) OVER w6 END AS games_minutes_slope_6
        ,CASE WHEN COUNT(shots_total) OVER w3 = 4 THEN -REGR_SLOPE(shots_total::real, match_number) OVER w3 END AS shots_total_slope_3
        ,CASE WHEN COUNT(shots_total) OVER w6 = 7 THEN -REGR_SLOPE(shots_total::real, match_number) OVER w6 END AS shots_total_slope_6
        ,CASE WHEN COUNT(shots_on) OVER w3 = 4 THEN -REGR_SLOPE(shots_on::real, match_number) OVER w3 END AS shots_on_slope_3
        ,CASE WHEN COUNT(shots_on) OVER w6 = 7 THEN -REGR_SLOPE(shots_on::real, match_number) OVER w6 END AS shots_on_slope_6
        ,CASE WHEN COUNT(goals_total) OVER w3 = 4 THEN -REGR_SLOPE(goals_total::real, match_number) OVER w3 END AS goals_total_slope_3
        ,CASE WHEN COUNT(goals_total) OVER w6 = 7 THEN -REGR_SLOPE(goals_total::real, match_number) OVER w6 END AS goals_total_slope_6
        ,CASE WHEN COUNT(goals_conceded) OVER w3 = 4 THEN -REGR_SLOPE(goals_conceded::real, match_number) OVER w3 END AS goals_conceded_slope_3
        ,CASE WHEN COUNT(goals_conceded) OVER w6 = 7 THEN -REGR_SLOPE(goals_conceded::real, match_number) OVER w6 END AS goals_conceded_slope_6
        ,CASE WHEN COUNT(goals_assists) OVER w3 = 4 THEN -REGR_SLOPE(goals_assists::real, match_number) OVER w3 END AS goals_assists_slope_3
        ,CASE WHEN COUNT(goals_assists) OVER w6 = 7 THEN -REGR_SLOPE(goals_assists::real, match_number) OVER w6 END AS goals_assists_slope_6
        ,CASE WHEN COUNT(goals_saves) OVER w3 = 4 THEN -REGR_SLOPE(goals_saves::real, match_number) OVER w3 END AS goals_saves_slope_3
        ,CASE WHEN COUNT(goals_saves) OVER w6 = 7 THEN -REGR_SLOPE(goals_saves::real, match_number) OVER w6 END AS goals_saves_slope_6
        ,CASE WHEN COUNT(passes_total) OVER w3 = 4 THEN -REGR_SLOPE(passes_total::real, match_number) OVER w3 END AS passes_total_slope_3
        ,CASE WHEN COUNT(passes_total) OVER w6 = 7 THEN -REGR_SLOPE(passes_total::real, match_number) OVER w6 END AS passes_total_slope_6
        ,CASE WHEN COUNT(passes_key) OVER w3 = 4 THEN -REGR_SLOPE(passes_key::real, match_number) OVER w3 END AS passes_key_slope_3
        ,CASE WHEN COUNT(passes_key) OVER w6 = 7 THEN -REGR_SLOPE(passes_key::real, match_number) OVER w6 END AS passes_key_slope_6
        ,CASE WHEN COUNT(passes_accuracy) OVER w3 = 4 THEN -REGR_SLOPE(passes_accuracy::real, match_number) OVER w3 END AS passes_accuracy_slope_3
        ,CASE WHEN COUNT(passes_accuracy) OVER w6 = 7 THEN -REGR_SLOPE(passes_accuracy::real, match_number) OVER w6 END AS passes_accuracy_slope_6
        ,CASE WHEN COUNT(tackles_total) OVER w3 = 4 THEN -REGR_SLOPE(tackles_total::real, match_number) OVER w3 END AS tackles_total_slope_3
        ,CASE WHEN COUNT(tackles_total) OVER w6 = 7 THEN -REGR_SLOPE(tackles_total::real, match_number) OVER w6 END AS tackles_total_slope_6
        ,CASE WHEN COUNT(tackles_blocks) OVER w3 = 4 THEN -REGR_SLOPE(tackles_blocks::real, match_number) OVER w3 END AS tackles_blocks_slope_3
        ,CASE WHEN COUNT(tackles_blocks) OVER w6 = 7 THEN -REGR_SLOPE(tackles_blocks::real, match_number) OVER w6 END AS tackles_blocks_slope_6
        ,CASE WHEN COUNT(tackles_interceptions) OVER w3 = 4 THEN -REGR_SLOPE(tackles_interceptions::real, match_number) OVER w3 END AS tackles_interceptions_slope_3
        ,CASE WHEN COUNT(tackles_interceptions) OVER w6 = 7 THEN -REGR_SLOPE(tackles_interceptions::real, match_number) OVER w6 END AS tackles_interceptions_slope_6
        ,CASE WHEN COUNT(duels_total) OVER w3 = 4 THEN -REGR_SLOPE(duels_total::real, match_number) OVER w3 END AS duels_total_slope_3
        ,CASE WHEN COUNT(duels_total) OVER w6 = 7 THEN -REGR_SLOPE(duels_total::real, match_number) OVER w6 END AS duels_total_slope_6
        ,CASE WHEN COUNT(duels_won) OVER w3 = 4 THEN -REGR_SLOPE(duels_won::real, match_number) OVER w3 END AS duels_won_slope_3
        ,CASE WHEN COUNT(duels_won) OVER w6 = 7 THEN -REGR_SLOPE(duels_won::real, match_number) OVER w6 END AS duels_won_slope_6
        ,CASE WHEN COUNT(dribbles_attempts) OVER w3 = 4 THEN -REGR_SLOPE(dribbles_attempts::real, match_number) OVER w3 END AS dribbles_attempts_slope_3
        ,CASE WHEN COUNT(dribbles_attempts) OVER w6 = 7 THEN -REGR_SLOPE(dribbles_attempts::real, match_number) OVER w6 END AS dribbles_attempts_slope_6
        ,CASE WHEN COUNT(dribbles_success) OVER w3 = 4 THEN -REGR_SLOPE(dribbles_success::real, match_number) OVER w3 END AS dribbles_success_slope_3
        ,CASE WHEN COUNT(dribbles_success) OVER w6 = 7 THEN -REGR_SLOPE(dribbles_success::real, match_number) OVER w6 END AS dribbles_success_slope_6
        ,CASE WHEN COUNT(dribbles_past) OVER w3 = 4 THEN -REGR_SLOPE(dribbles_past::real, match_number) OVER w3 END AS dribbles_past_slope_3
        ,CASE WHEN COUNT(dribbles_past) OVER w6 = 7 THEN -REGR_SLOPE(dribbles_past::real, match_number) OVER w6 END AS dribbles_past_slope_6
        ,CASE WHEN COUNT(fouls_drawn) OVER w3 = 4 THEN -REGR_SLOPE(fouls_drawn::real, match_number) OVER w3 END AS fouls_drawn_slope_3
        ,CASE WHEN COUNT(fouls_drawn) OVER w6 = 7 THEN -REGR_SLOPE(fouls_drawn::real, match_number) OVER w6 END AS fouls_drawn_slope_6
        ,CASE WHEN COUNT(fouls_committed) OVER w3 = 4 THEN -REGR_SLOPE(fouls_committed::real, match_number) OVER w3 END AS fouls_committed_slope_3
        ,CASE WHEN COUNT(fouls_committed) OVER w6 = 7 THEN -REGR_SLOPE(fouls_committed::real, match_number) OVER w6 END AS fouls_committed_slope_6
        ,CASE WHEN COUNT(cards_yellow) OVER w3 = 4 THEN -REGR_SLOPE(cards_yellow::real, match_number) OVER w3 END AS cards_yellow_slope_3
        ,CASE WHEN COUNT(cards_yellow) OVER w6 = 7 THEN -REGR_SLOPE(cards_yellow::real, match_number) OVER w6 END AS cards_yellow_slope_6
        ,CASE WHEN COUNT(cards_red) OVER w3 = 4 THEN -REGR_SLOPE(cards_red::real, match_number) OVER w3 END AS cards_red_slope_3
        ,CASE WHEN COUNT(cards_red) OVER w6 = 7 THEN -REGR_SLOPE(cards_red::real, match_number) OVER w6 END AS cards_red_slope_6
        ,CASE WHEN COUNT(penalty_won) OVER w3 = 4 THEN -REGR_SLOPE(penalty_won::real, match_number) OVER w3 END AS penalty_won_slope_3
        ,CASE WHEN COUNT(penalty_won) OVER w6 = 7 THEN -REGR_SLOPE(penalty_won::real, match_number) OVER w6 END AS penalty_won_slope_6
        ,CASE WHEN COUNT(penalty_commited) OVER w3 = 4 THEN -REGR_SLOPE(penalty_commited::real, match_number) OVER w3 END AS penalty_commited_slope_3
        ,CASE WHEN COUNT(penalty_commited) OVER w6 = 7 THEN -REGR_SLOPE(penalty_commited::real, match_number) OVER w6 END AS penalty_commited_slope_6
        ,CASE WHEN COUNT(penalty_scored) OVER w3 = 4 THEN -REGR_SLOPE(penalty_scored::real, match_number) OVER w3 END AS penalty_scored_slope_3
        ,CASE WHEN COUNT(penalty_scored) OVER w6 = 7 THEN -REGR_SLOPE(penalty_scored::real, match_number) OVER w6 END AS penalty_scored_slope_6
        ,CASE WHEN COUNT(penalty_missed) OVER w3 = 4 THEN -REGR_SLOPE(penalty_missed::real, match_number) OVER w3 END AS penalty_missed_slope_3
        ,CASE WHEN COUNT(penalty_missed) OVER w6 = 7 THEN -REGR_SLOPE(penalty_missed::real, match_number) OVER w6 END AS penalty_missed_slope_6
        ,CASE WHEN COUNT(penalty_saved) OVER w3 = 4 THEN -REGR_SLOPE(penalty_saved::real, match_number) OVER w3 END AS penalty_saved_slope_3
        ,CASE WHEN COUNT(penalty_saved) OVER w6 = 7 THEN -REGR_SLOPE(penalty_saved::real, match_number) OVER w6 END AS penalty_saved_slope_6
        ,CASE WHEN COUNT(goals) OVER w3 = 4 THEN -REGR_SLOPE(goals::real, match_number) OVER w3 END AS goals_slope_t3
        ,CASE WHEN COUNT(goals) OVER w6 = 7 THEN -REGR_SLOPE(goals::real, match_number) OVER w6 END AS goals_slope_t6
    FROM numbered_matches t1

    WINDOW
        w3 AS (
            PARTITION BY team_id
            ORDER BY date, fixture_id
            ROWS BETWEEN 3 PRECEDING AND 1 PRECEDING
        ),
        w6 AS (
            PARTITION BY team_id
            ORDER BY date, fixture_id
            ROWS BETWEEN 6 PRECEDING AND 1 PRECEDING
        )
)
SELECT *
FROM metrics;


-- Maxes, Mins, Sums, Averages, Counts

DROP TABLE IF EXISTS transformed_prod_match_summary_sum_avg_max_min;
CREATE TEMP TABLE transformed_prod_match_summary_sum_avg_max_min AS
-- WITH numbered_matches AS (
--     SELECT
--         t1.*,
--         ROW_NUMBER() OVER (
--             PARTITION BY team_id, league_season
--             ORDER BY date, fixture_id
--         )::real AS match_number
--     FROM transformed_prod_match_summary t1
-- ),
WITH metrics AS (
    SELECT
        fixture_id
        ,date
        ,venue_id
        ,venue_name
        ,status_elapsed
        ,status_extra
        ,league_id
        ,team_id
        ,goals
        ,is_winner
        ,is_home
        ,league_season
        ,SUM(shots_on_goal) OVER w3 AS sum_shots_on_goal_3
        ,SUM(shots_on_goal) OVER w6 AS sum_shots_on_goal_6
        ,SUM(shots_off_goal) OVER w3 AS sum_shots_off_goal_3
        ,SUM(shots_off_goal) OVER w6 AS sum_shots_off_goal_6
        ,SUM(total_shots) OVER w3 AS sum_total_shots_3
        ,SUM(total_shots) OVER w6 AS sum_total_shots_6
        ,SUM(blocked_shots) OVER w3 AS sum_blocked_shots_3
        ,SUM(blocked_shots) OVER w6 AS sum_blocked_shots_6
        ,SUM(shots_insidebox) OVER w3 AS sum_shots_insidebox_3
        ,SUM(shots_insidebox) OVER w6 AS sum_shots_insidebox_6
        ,SUM(shots_outsidebox) OVER w3 AS sum_shots_outsidebox_3
        ,SUM(shots_outsidebox) OVER w6 AS sum_shots_outsidebox_6
        ,SUM(fouls) OVER w3 AS sum_fouls_3
        ,SUM(fouls) OVER w6 AS sum_fouls_6
        ,SUM(corner_kicks) OVER w3 AS sum_corner_kicks_3
        ,SUM(corner_kicks) OVER w6 AS sum_corner_kicks_6
        ,SUM(offsides) OVER w3 AS sum_offsides_3
        ,SUM(offsides) OVER w6 AS sum_offsides_6
        ,SUM(ball_possession) OVER w3 AS sum_ball_possession_3
        ,SUM(ball_possession) OVER w6 AS sum_ball_possession_6
        ,SUM(yellow_cards) OVER w3 AS sum_yellow_cards_3
        ,SUM(yellow_cards) OVER w6 AS sum_yellow_cards_6
        ,SUM(red_cards) OVER w3 AS sum_red_cards_3
        ,SUM(red_cards) OVER w6 AS sum_red_cards_6
        ,SUM(goalkeeper_saves) OVER w3 AS sum_goalkeeper_saves_3
        ,SUM(goalkeeper_saves) OVER w6 AS sum_goalkeeper_saves_6
        ,SUM(total_passes) OVER w3 AS sum_total_passes_3
        ,SUM(total_passes) OVER w6 AS sum_total_passes_6
        ,SUM(passes_accurate) OVER w3 AS sum_passes_accurate_3
        ,SUM(passes_accurate) OVER w6 AS sum_passes_accurate_6
        ,SUM(passes_perc) OVER w3 AS sum_passes_perc_3
        ,SUM(passes_perc) OVER w6 AS sum_passes_perc_6
        ,SUM(goals_prevented) OVER w3 AS sum_goals_prevented_3
        ,SUM(goals_prevented) OVER w6 AS sum_goals_prevented_6
        ,SUM(card_reviewed) OVER w3 AS sum_card_reviewed_3
        ,SUM(card_reviewed) OVER w6 AS sum_card_reviewed_6
        ,SUM(card_upgrade) OVER w3 AS sum_card_upgrade_3
        ,SUM(card_upgrade) OVER w6 AS sum_card_upgrade_6
        ,SUM(goal_cancelled) OVER w3 AS sum_goal_cancelled_3
        ,SUM(goal_cancelled) OVER w6 AS sum_goal_cancelled_6
        ,SUM(goal_confirmed) OVER w3 AS sum_goal_confirmed_3
        ,SUM(goal_confirmed) OVER w6 AS sum_goal_confirmed_6
        ,SUM(goal_disallowed) OVER w3 AS sum_goal_disallowed_3
        ,SUM(goal_disallowed) OVER w6 AS sum_goal_disallowed_6
        ,SUM(goal_disallowed_foul) OVER w3 AS sum_goal_disallowed_foul_3
        ,SUM(goal_disallowed_foul) OVER w6 AS sum_goal_disallowed_foul_6
        ,SUM(goal_disallowed_handball) OVER w3 AS sum_goal_disallowed_handball_3
        ,SUM(goal_disallowed_handball) OVER w6 AS sum_goal_disallowed_handball_6
        ,SUM(goal_disallowed_offside) OVER w3 AS sum_goal_disallowed_offside_3
        ,SUM(goal_disallowed_offside) OVER w6 AS sum_goal_disallowed_offside_6
        ,SUM(missed_penalty) OVER w3 AS sum_missed_penalty_3
        ,SUM(missed_penalty) OVER w6 AS sum_missed_penalty_6
        ,SUM(normal_goal) OVER w3 AS sum_normal_goal_3
        ,SUM(normal_goal) OVER w6 AS sum_normal_goal_6
        ,SUM(own_goal) OVER w3 AS sum_own_goal_3
        ,SUM(own_goal) OVER w6 AS sum_own_goal_6
        ,SUM(penalty) OVER w3 AS sum_penalty_3
        ,SUM(penalty) OVER w6 AS sum_penalty_6
        ,SUM(penalty_awarded) OVER w3 AS sum_penalty_awarded_3
        ,SUM(penalty_awarded) OVER w6 AS sum_penalty_awarded_6
        ,SUM(penalty_cancelled) OVER w3 AS sum_penalty_cancelled_3
        ,SUM(penalty_cancelled) OVER w6 AS sum_penalty_cancelled_6
        ,SUM(penalty_confirmed) OVER w3 AS sum_penalty_confirmed_3
        ,SUM(penalty_confirmed) OVER w6 AS sum_penalty_confirmed_6
        ,SUM(red_card) OVER w3 AS sum_red_card_3
        ,SUM(red_card) OVER w6 AS sum_red_card_6
        ,SUM(red_card_cancelled) OVER w3 AS sum_red_card_cancelled_3
        ,SUM(red_card_cancelled) OVER w6 AS sum_red_card_cancelled_6
        ,SUM(substitution_1) OVER w3 AS sum_substitution_1_3
        ,SUM(substitution_1) OVER w6 AS sum_substitution_1_6
        ,SUM(substitution_10) OVER w3 AS sum_substitution_10_3
        ,SUM(substitution_10) OVER w6 AS sum_substitution_10_6
        ,SUM(substitution_11) OVER w3 AS sum_substitution_11_3
        ,SUM(substitution_11) OVER w6 AS sum_substitution_11_6
        ,SUM(substitution_12) OVER w3 AS sum_substitution_12_3
        ,SUM(substitution_12) OVER w6 AS sum_substitution_12_6
        ,SUM(substitution_13) OVER w3 AS sum_substitution_13_3
        ,SUM(substitution_13) OVER w6 AS sum_substitution_13_6
        ,SUM(substitution_14) OVER w3 AS sum_substitution_14_3
        ,SUM(substitution_14) OVER w6 AS sum_substitution_14_6
        ,SUM(substitution_15) OVER w3 AS sum_substitution_15_3
        ,SUM(substitution_15) OVER w6 AS sum_substitution_15_6
        ,SUM(substitution_16) OVER w3 AS sum_substitution_16_3
        ,SUM(substitution_16) OVER w6 AS sum_substitution_16_6
        ,SUM(substitution_17) OVER w3 AS sum_substitution_17_3
        ,SUM(substitution_17) OVER w6 AS sum_substitution_17_6
        ,SUM(substitution_18) OVER w3 AS sum_substitution_18_3
        ,SUM(substitution_18) OVER w6 AS sum_substitution_18_6
        ,SUM(substitution_2) OVER w3 AS sum_substitution_2_3
        ,SUM(substitution_2) OVER w6 AS sum_substitution_2_6
        ,SUM(substitution_3) OVER w3 AS sum_substitution_3_3
        ,SUM(substitution_3) OVER w6 AS sum_substitution_3_6
        ,SUM(substitution_4) OVER w3 AS sum_substitution_4_3
        ,SUM(substitution_4) OVER w6 AS sum_substitution_4_6
        ,SUM(substitution_5) OVER w3 AS sum_substitution_5_3
        ,SUM(substitution_5) OVER w6 AS sum_substitution_5_6
        ,SUM(substitution_6) OVER w3 AS sum_substitution_6_3
        ,SUM(substitution_6) OVER w6 AS sum_substitution_6_6
        ,SUM(substitution_7) OVER w3 AS sum_substitution_7_3
        ,SUM(substitution_7) OVER w6 AS sum_substitution_7_6
        ,SUM(substitution_8) OVER w3 AS sum_substitution_8_3
        ,SUM(substitution_8) OVER w6 AS sum_substitution_8_6
        ,SUM(substitution_9) OVER w3 AS sum_substitution_9_3
        ,SUM(substitution_9) OVER w6 AS sum_substitution_9_6
        ,SUM(yellow_card) OVER w3 AS sum_yellow_card_3
        ,SUM(yellow_card) OVER w6 AS sum_yellow_card_6
        ,SUM(games_minutes) OVER w3 AS sum_games_minutes_3
        ,SUM(games_minutes) OVER w6 AS sum_games_minutes_6
        ,SUM(shots_total) OVER w3 AS sum_shots_total_3
        ,SUM(shots_total) OVER w6 AS sum_shots_total_6
        ,SUM(shots_on) OVER w3 AS sum_shots_on_3
        ,SUM(shots_on) OVER w6 AS sum_shots_on_6
        ,SUM(goals_total) OVER w3 AS sum_goals_total_3
        ,SUM(goals_total) OVER w6 AS sum_goals_total_6
        ,SUM(goals_conceded) OVER w3 AS sum_goals_conceded_3
        ,SUM(goals_conceded) OVER w6 AS sum_goals_conceded_6
        ,SUM(goals_assists) OVER w3 AS sum_goals_assists_3
        ,SUM(goals_assists) OVER w6 AS sum_goals_assists_6
        ,SUM(goals_saves) OVER w3 AS sum_goals_saves_3
        ,SUM(goals_saves) OVER w6 AS sum_goals_saves_6
        ,SUM(passes_total) OVER w3 AS sum_passes_total_3
        ,SUM(passes_total) OVER w6 AS sum_passes_total_6
        ,SUM(passes_key) OVER w3 AS sum_passes_key_3
        ,SUM(passes_key) OVER w6 AS sum_passes_key_6
        ,SUM(passes_accuracy) OVER w3 AS sum_passes_accuracy_3
        ,SUM(passes_accuracy) OVER w6 AS sum_passes_accuracy_6
        ,SUM(tackles_total) OVER w3 AS sum_tackles_total_3
        ,SUM(tackles_total) OVER w6 AS sum_tackles_total_6
        ,SUM(tackles_blocks) OVER w3 AS sum_tackles_blocks_3
        ,SUM(tackles_blocks) OVER w6 AS sum_tackles_blocks_6
        ,SUM(tackles_interceptions) OVER w3 AS sum_tackles_interceptions_3
        ,SUM(tackles_interceptions) OVER w6 AS sum_tackles_interceptions_6
        ,SUM(duels_total) OVER w3 AS sum_duels_total_3
        ,SUM(duels_total) OVER w6 AS sum_duels_total_6
        ,SUM(duels_won) OVER w3 AS sum_duels_won_3
        ,SUM(duels_won) OVER w6 AS sum_duels_won_6
        ,SUM(dribbles_attempts) OVER w3 AS sum_dribbles_attempts_3
        ,SUM(dribbles_attempts) OVER w6 AS sum_dribbles_attempts_6
        ,SUM(dribbles_success) OVER w3 AS sum_dribbles_success_3
        ,SUM(dribbles_success) OVER w6 AS sum_dribbles_success_6
        ,SUM(dribbles_past) OVER w3 AS sum_dribbles_past_3
        ,SUM(dribbles_past) OVER w6 AS sum_dribbles_past_6
        ,SUM(fouls_drawn) OVER w3 AS sum_fouls_drawn_3
        ,SUM(fouls_drawn) OVER w6 AS sum_fouls_drawn_6
        ,SUM(fouls_committed) OVER w3 AS sum_fouls_committed_3
        ,SUM(fouls_committed) OVER w6 AS sum_fouls_committed_6
        ,SUM(cards_yellow) OVER w3 AS sum_cards_yellow_3
        ,SUM(cards_yellow) OVER w6 AS sum_cards_yellow_6
        ,SUM(cards_red) OVER w3 AS sum_cards_red_3
        ,SUM(cards_red) OVER w6 AS sum_cards_red_6
        ,SUM(penalty_won) OVER w3 AS sum_penalty_won_3
        ,SUM(penalty_won) OVER w6 AS sum_penalty_won_6
        ,SUM(penalty_commited) OVER w3 AS sum_penalty_commited_3
        ,SUM(penalty_commited) OVER w6 AS sum_penalty_commited_6
        ,SUM(penalty_scored) OVER w3 AS sum_penalty_scored_3
        ,SUM(penalty_scored) OVER w6 AS sum_penalty_scored_6
        ,SUM(penalty_missed) OVER w3 AS sum_penalty_missed_3
        ,SUM(penalty_missed) OVER w6 AS sum_penalty_missed_6
        ,SUM(penalty_saved) OVER w3 AS sum_penalty_saved_3
        ,SUM(penalty_saved) OVER w6 AS sum_penalty_saved_6
        ,AVG(shots_on_goal) OVER w3 AS avg_shots_on_goal_3
        ,MAX(shots_on_goal) OVER w3 AS max_shots_on_goal_3
        ,MIN(shots_on_goal) OVER w3 AS min_shots_on_goal_3
        ,AVG(shots_on_goal) OVER w6 AS avg_shots_on_goal_6
        ,MAX(shots_on_goal) OVER w6 AS max_shots_on_goal_6
        ,MIN(shots_on_goal) OVER w6 AS min_shots_on_goal_6
        ,AVG(shots_off_goal) OVER w3 AS avg_shots_off_goal_3
        ,MAX(shots_off_goal) OVER w3 AS max_shots_off_goal_3
        ,MIN(shots_off_goal) OVER w3 AS min_shots_off_goal_3
        ,AVG(shots_off_goal) OVER w6 AS avg_shots_off_goal_6
        ,MAX(shots_off_goal) OVER w6 AS max_shots_off_goal_6
        ,MIN(shots_off_goal) OVER w6 AS min_shots_off_goal_6
        ,AVG(total_shots) OVER w3 AS avg_total_shots_3
        ,MAX(total_shots) OVER w3 AS max_total_shots_3
        ,MIN(total_shots) OVER w3 AS min_total_shots_3
        ,AVG(total_shots) OVER w6 AS avg_total_shots_6
        ,MAX(total_shots) OVER w6 AS max_total_shots_6
        ,MIN(total_shots) OVER w6 AS min_total_shots_6
        ,AVG(blocked_shots) OVER w3 AS avg_blocked_shots_3
        ,MAX(blocked_shots) OVER w3 AS max_blocked_shots_3
        ,MIN(blocked_shots) OVER w3 AS min_blocked_shots_3
        ,AVG(blocked_shots) OVER w6 AS avg_blocked_shots_6
        ,MAX(blocked_shots) OVER w6 AS max_blocked_shots_6
        ,MIN(blocked_shots) OVER w6 AS min_blocked_shots_6
        ,AVG(shots_insidebox) OVER w3 AS avg_shots_insidebox_3
        ,MAX(shots_insidebox) OVER w3 AS max_shots_insidebox_3
        ,MIN(shots_insidebox) OVER w3 AS min_shots_insidebox_3
        ,AVG(shots_insidebox) OVER w6 AS avg_shots_insidebox_6
        ,MAX(shots_insidebox) OVER w6 AS max_shots_insidebox_6
        ,MIN(shots_insidebox) OVER w6 AS min_shots_insidebox_6
        ,AVG(shots_outsidebox) OVER w3 AS avg_shots_outsidebox_3
        ,MAX(shots_outsidebox) OVER w3 AS max_shots_outsidebox_3
        ,MIN(shots_outsidebox) OVER w3 AS min_shots_outsidebox_3
        ,AVG(shots_outsidebox) OVER w6 AS avg_shots_outsidebox_6
        ,MAX(shots_outsidebox) OVER w6 AS max_shots_outsidebox_6
        ,MIN(shots_outsidebox) OVER w6 AS min_shots_outsidebox_6
        ,AVG(fouls) OVER w3 AS avg_fouls_3
        ,MAX(fouls) OVER w3 AS max_fouls_3
        ,MIN(fouls) OVER w3 AS min_fouls_3
        ,AVG(fouls) OVER w6 AS avg_fouls_6
        ,MAX(fouls) OVER w6 AS max_fouls_6
        ,MIN(fouls) OVER w6 AS min_fouls_6
        ,AVG(corner_kicks) OVER w3 AS avg_corner_kicks_3
        ,MAX(corner_kicks) OVER w3 AS max_corner_kicks_3
        ,MIN(corner_kicks) OVER w3 AS min_corner_kicks_3
        ,AVG(corner_kicks) OVER w6 AS avg_corner_kicks_6
        ,MAX(corner_kicks) OVER w6 AS max_corner_kicks_6
        ,MIN(corner_kicks) OVER w6 AS min_corner_kicks_6
        ,AVG(offsides) OVER w3 AS avg_offsides_3
        ,MAX(offsides) OVER w3 AS max_offsides_3
        ,MIN(offsides) OVER w3 AS min_offsides_3
        ,AVG(offsides) OVER w6 AS avg_offsides_6
        ,MAX(offsides) OVER w6 AS max_offsides_6
        ,MIN(offsides) OVER w6 AS min_offsides_6
        ,AVG(ball_possession) OVER w3 AS avg_ball_possession_3
        ,MAX(ball_possession) OVER w3 AS max_ball_possession_3
        ,MIN(ball_possession) OVER w3 AS min_ball_possession_3
        ,AVG(ball_possession) OVER w6 AS avg_ball_possession_6
        ,MAX(ball_possession) OVER w6 AS max_ball_possession_6
        ,MIN(ball_possession) OVER w6 AS min_ball_possession_6
        ,AVG(yellow_cards) OVER w3 AS avg_yellow_cards_3
        ,MAX(yellow_cards) OVER w3 AS max_yellow_cards_3
        ,MIN(yellow_cards) OVER w3 AS min_yellow_cards_3
        ,AVG(yellow_cards) OVER w6 AS avg_yellow_cards_6
        ,MAX(yellow_cards) OVER w6 AS max_yellow_cards_6
        ,MIN(yellow_cards) OVER w6 AS min_yellow_cards_6
        ,AVG(red_cards) OVER w3 AS avg_red_cards_3
        ,MAX(red_cards) OVER w3 AS max_red_cards_3
        ,MIN(red_cards) OVER w3 AS min_red_cards_3
        ,AVG(red_cards) OVER w6 AS avg_red_cards_6
        ,MAX(red_cards) OVER w6 AS max_red_cards_6
        ,MIN(red_cards) OVER w6 AS min_red_cards_6
        ,AVG(goalkeeper_saves) OVER w3 AS avg_goalkeeper_saves_3
        ,MAX(goalkeeper_saves) OVER w3 AS max_goalkeeper_saves_3
        ,MIN(goalkeeper_saves) OVER w3 AS min_goalkeeper_saves_3
        ,AVG(goalkeeper_saves) OVER w6 AS avg_goalkeeper_saves_6
        ,MAX(goalkeeper_saves) OVER w6 AS max_goalkeeper_saves_6
        ,MIN(goalkeeper_saves) OVER w6 AS min_goalkeeper_saves_6
        ,AVG(total_passes) OVER w3 AS avg_total_passes_3
        ,MAX(total_passes) OVER w3 AS max_total_passes_3
        ,MIN(total_passes) OVER w3 AS min_total_passes_3
        ,AVG(total_passes) OVER w6 AS avg_total_passes_6
        ,MAX(total_passes) OVER w6 AS max_total_passes_6
        ,MIN(total_passes) OVER w6 AS min_total_passes_6
        ,AVG(passes_accurate) OVER w3 AS avg_passes_accurate_3
        ,MAX(passes_accurate) OVER w3 AS max_passes_accurate_3
        ,MIN(passes_accurate) OVER w3 AS min_passes_accurate_3
        ,AVG(passes_accurate) OVER w6 AS avg_passes_accurate_6
        ,MAX(passes_accurate) OVER w6 AS max_passes_accurate_6
        ,MIN(passes_accurate) OVER w6 AS min_passes_accurate_6
        ,AVG(passes_perc) OVER w3 AS avg_passes_perc_3
        ,MAX(passes_perc) OVER w3 AS max_passes_perc_3
        ,MIN(passes_perc) OVER w3 AS min_passes_perc_3
        ,AVG(passes_perc) OVER w6 AS avg_passes_perc_6
        ,MAX(passes_perc) OVER w6 AS max_passes_perc_6
        ,MIN(passes_perc) OVER w6 AS min_passes_perc_6
        ,AVG(goals_prevented) OVER w3 AS avg_goals_prevented_3
        ,MAX(goals_prevented) OVER w3 AS max_goals_prevented_3
        ,MIN(goals_prevented) OVER w3 AS min_goals_prevented_3
        ,AVG(goals_prevented) OVER w6 AS avg_goals_prevented_6
        ,MAX(goals_prevented) OVER w6 AS max_goals_prevented_6
        ,MIN(goals_prevented) OVER w6 AS min_goals_prevented_6
        ,AVG(card_reviewed) OVER w3 AS avg_card_reviewed_3
        ,MAX(card_reviewed) OVER w3 AS max_card_reviewed_3
        ,MIN(card_reviewed) OVER w3 AS min_card_reviewed_3
        ,AVG(card_reviewed) OVER w6 AS avg_card_reviewed_6
        ,MAX(card_reviewed) OVER w6 AS max_card_reviewed_6
        ,MIN(card_reviewed) OVER w6 AS min_card_reviewed_6
        ,AVG(card_upgrade) OVER w3 AS avg_card_upgrade_3
        ,MAX(card_upgrade) OVER w3 AS max_card_upgrade_3
        ,MIN(card_upgrade) OVER w3 AS min_card_upgrade_3
        ,AVG(card_upgrade) OVER w6 AS avg_card_upgrade_6
        ,MAX(card_upgrade) OVER w6 AS max_card_upgrade_6
        ,MIN(card_upgrade) OVER w6 AS min_card_upgrade_6
        ,AVG(goal_cancelled) OVER w3 AS avg_goal_cancelled_3
        ,MAX(goal_cancelled) OVER w3 AS max_goal_cancelled_3
        ,MIN(goal_cancelled) OVER w3 AS min_goal_cancelled_3
        ,AVG(goal_cancelled) OVER w6 AS avg_goal_cancelled_6
        ,MAX(goal_cancelled) OVER w6 AS max_goal_cancelled_6
        ,MIN(goal_cancelled) OVER w6 AS min_goal_cancelled_6
        ,AVG(goal_confirmed) OVER w3 AS avg_goal_confirmed_3
        ,MAX(goal_confirmed) OVER w3 AS max_goal_confirmed_3
        ,MIN(goal_confirmed) OVER w3 AS min_goal_confirmed_3
        ,AVG(goal_confirmed) OVER w6 AS avg_goal_confirmed_6
        ,MAX(goal_confirmed) OVER w6 AS max_goal_confirmed_6
        ,MIN(goal_confirmed) OVER w6 AS min_goal_confirmed_6
        ,AVG(goal_disallowed) OVER w3 AS avg_goal_disallowed_3
        ,MAX(goal_disallowed) OVER w3 AS max_goal_disallowed_3
        ,MIN(goal_disallowed) OVER w3 AS min_goal_disallowed_3
        ,AVG(goal_disallowed) OVER w6 AS avg_goal_disallowed_6
        ,MAX(goal_disallowed) OVER w6 AS max_goal_disallowed_6
        ,MIN(goal_disallowed) OVER w6 AS min_goal_disallowed_6
        ,AVG(goal_disallowed_foul) OVER w3 AS avg_goal_disallowed_foul_3
        ,MAX(goal_disallowed_foul) OVER w3 AS max_goal_disallowed_foul_3
        ,MIN(goal_disallowed_foul) OVER w3 AS min_goal_disallowed_foul_3
        ,AVG(goal_disallowed_foul) OVER w6 AS avg_goal_disallowed_foul_6
        ,MAX(goal_disallowed_foul) OVER w6 AS max_goal_disallowed_foul_6
        ,MIN(goal_disallowed_foul) OVER w6 AS min_goal_disallowed_foul_6
        ,AVG(goal_disallowed_handball) OVER w3 AS avg_goal_disallowed_handball_3
        ,MAX(goal_disallowed_handball) OVER w3 AS max_goal_disallowed_handball_3
        ,MIN(goal_disallowed_handball) OVER w3 AS min_goal_disallowed_handball_3
        ,AVG(goal_disallowed_handball) OVER w6 AS avg_goal_disallowed_handball_6
        ,MAX(goal_disallowed_handball) OVER w6 AS max_goal_disallowed_handball_6
        ,MIN(goal_disallowed_handball) OVER w6 AS min_goal_disallowed_handball_6
        ,AVG(goal_disallowed_offside) OVER w3 AS avg_goal_disallowed_offside_3
        ,MAX(goal_disallowed_offside) OVER w3 AS max_goal_disallowed_offside_3
        ,MIN(goal_disallowed_offside) OVER w3 AS min_goal_disallowed_offside_3
        ,AVG(goal_disallowed_offside) OVER w6 AS avg_goal_disallowed_offside_6
        ,MAX(goal_disallowed_offside) OVER w6 AS max_goal_disallowed_offside_6
        ,MIN(goal_disallowed_offside) OVER w6 AS min_goal_disallowed_offside_6
        ,AVG(missed_penalty) OVER w3 AS avg_missed_penalty_3
        ,MAX(missed_penalty) OVER w3 AS max_missed_penalty_3
        ,MIN(missed_penalty) OVER w3 AS min_missed_penalty_3
        ,AVG(missed_penalty) OVER w6 AS avg_missed_penalty_6
        ,MAX(missed_penalty) OVER w6 AS max_missed_penalty_6
        ,MIN(missed_penalty) OVER w6 AS min_missed_penalty_6
        ,AVG(normal_goal) OVER w3 AS avg_normal_goal_3
        ,MAX(normal_goal) OVER w3 AS max_normal_goal_3
        ,MIN(normal_goal) OVER w3 AS min_normal_goal_3
        ,AVG(normal_goal) OVER w6 AS avg_normal_goal_6
        ,MAX(normal_goal) OVER w6 AS max_normal_goal_6
        ,MIN(normal_goal) OVER w6 AS min_normal_goal_6
        ,AVG(own_goal) OVER w3 AS avg_own_goal_3
        ,MAX(own_goal) OVER w3 AS max_own_goal_3
        ,MIN(own_goal) OVER w3 AS min_own_goal_3
        ,AVG(own_goal) OVER w6 AS avg_own_goal_6
        ,MAX(own_goal) OVER w6 AS max_own_goal_6
        ,MIN(own_goal) OVER w6 AS min_own_goal_6
        ,AVG(penalty) OVER w3 AS avg_penalty_3
        ,MAX(penalty) OVER w3 AS max_penalty_3
        ,MIN(penalty) OVER w3 AS min_penalty_3
        ,AVG(penalty) OVER w6 AS avg_penalty_6
        ,MAX(penalty) OVER w6 AS max_penalty_6
        ,MIN(penalty) OVER w6 AS min_penalty_6
        ,AVG(penalty_awarded) OVER w3 AS avg_penalty_awarded_3
        ,MAX(penalty_awarded) OVER w3 AS max_penalty_awarded_3
        ,MIN(penalty_awarded) OVER w3 AS min_penalty_awarded_3
        ,AVG(penalty_awarded) OVER w6 AS avg_penalty_awarded_6
        ,MAX(penalty_awarded) OVER w6 AS max_penalty_awarded_6
        ,MIN(penalty_awarded) OVER w6 AS min_penalty_awarded_6
        ,AVG(penalty_cancelled) OVER w3 AS avg_penalty_cancelled_3
        ,MAX(penalty_cancelled) OVER w3 AS max_penalty_cancelled_3
        ,MIN(penalty_cancelled) OVER w3 AS min_penalty_cancelled_3
        ,AVG(penalty_cancelled) OVER w6 AS avg_penalty_cancelled_6
        ,MAX(penalty_cancelled) OVER w6 AS max_penalty_cancelled_6
        ,MIN(penalty_cancelled) OVER w6 AS min_penalty_cancelled_6
        ,AVG(penalty_confirmed) OVER w3 AS avg_penalty_confirmed_3
        ,MAX(penalty_confirmed) OVER w3 AS max_penalty_confirmed_3
        ,MIN(penalty_confirmed) OVER w3 AS min_penalty_confirmed_3
        ,AVG(penalty_confirmed) OVER w6 AS avg_penalty_confirmed_6
        ,MAX(penalty_confirmed) OVER w6 AS max_penalty_confirmed_6
        ,MIN(penalty_confirmed) OVER w6 AS min_penalty_confirmed_6
        ,AVG(red_card) OVER w3 AS avg_red_card_3
        ,MAX(red_card) OVER w3 AS max_red_card_3
        ,MIN(red_card) OVER w3 AS min_red_card_3
        ,AVG(red_card) OVER w6 AS avg_red_card_6
        ,MAX(red_card) OVER w6 AS max_red_card_6
        ,MIN(red_card) OVER w6 AS min_red_card_6
        ,AVG(red_card_cancelled) OVER w3 AS avg_red_card_cancelled_3
        ,MAX(red_card_cancelled) OVER w3 AS max_red_card_cancelled_3
        ,MIN(red_card_cancelled) OVER w3 AS min_red_card_cancelled_3
        ,AVG(red_card_cancelled) OVER w6 AS avg_red_card_cancelled_6
        ,MAX(red_card_cancelled) OVER w6 AS max_red_card_cancelled_6
        ,MIN(red_card_cancelled) OVER w6 AS min_red_card_cancelled_6
        ,AVG(substitution_1) OVER w3 AS avg_substitution_1_3
        ,MAX(substitution_1) OVER w3 AS max_substitution_1_3
        ,MIN(substitution_1) OVER w3 AS min_substitution_1_3
        ,AVG(substitution_1) OVER w6 AS avg_substitution_1_6
        ,MAX(substitution_1) OVER w6 AS max_substitution_1_6
        ,MIN(substitution_1) OVER w6 AS min_substitution_1_6
        ,AVG(substitution_10) OVER w3 AS avg_substitution_10_3
        ,MAX(substitution_10) OVER w3 AS max_substitution_10_3
        ,MIN(substitution_10) OVER w3 AS min_substitution_10_3
        ,AVG(substitution_10) OVER w6 AS avg_substitution_10_6
        ,MAX(substitution_10) OVER w6 AS max_substitution_10_6
        ,MIN(substitution_10) OVER w6 AS min_substitution_10_6
        ,AVG(substitution_11) OVER w3 AS avg_substitution_11_3
        ,MAX(substitution_11) OVER w3 AS max_substitution_11_3
        ,MIN(substitution_11) OVER w3 AS min_substitution_11_3
        ,AVG(substitution_11) OVER w6 AS avg_substitution_11_6
        ,MAX(substitution_11) OVER w6 AS max_substitution_11_6
        ,MIN(substitution_11) OVER w6 AS min_substitution_11_6
        ,AVG(substitution_12) OVER w3 AS avg_substitution_12_3
        ,MAX(substitution_12) OVER w3 AS max_substitution_12_3
        ,MIN(substitution_12) OVER w3 AS min_substitution_12_3
        ,AVG(substitution_12) OVER w6 AS avg_substitution_12_6
        ,MAX(substitution_12) OVER w6 AS max_substitution_12_6
        ,MIN(substitution_12) OVER w6 AS min_substitution_12_6
        ,AVG(substitution_13) OVER w3 AS avg_substitution_13_3
        ,MAX(substitution_13) OVER w3 AS max_substitution_13_3
        ,MIN(substitution_13) OVER w3 AS min_substitution_13_3
        ,AVG(substitution_13) OVER w6 AS avg_substitution_13_6
        ,MAX(substitution_13) OVER w6 AS max_substitution_13_6
        ,MIN(substitution_13) OVER w6 AS min_substitution_13_6
        ,AVG(substitution_14) OVER w3 AS avg_substitution_14_3
        ,MAX(substitution_14) OVER w3 AS max_substitution_14_3
        ,MIN(substitution_14) OVER w3 AS min_substitution_14_3
        ,AVG(substitution_14) OVER w6 AS avg_substitution_14_6
        ,MAX(substitution_14) OVER w6 AS max_substitution_14_6
        ,MIN(substitution_14) OVER w6 AS min_substitution_14_6
        ,AVG(substitution_15) OVER w3 AS avg_substitution_15_3
        ,MAX(substitution_15) OVER w3 AS max_substitution_15_3
        ,MIN(substitution_15) OVER w3 AS min_substitution_15_3
        ,AVG(substitution_15) OVER w6 AS avg_substitution_15_6
        ,MAX(substitution_15) OVER w6 AS max_substitution_15_6
        ,MIN(substitution_15) OVER w6 AS min_substitution_15_6
        ,AVG(substitution_16) OVER w3 AS avg_substitution_16_3
        ,MAX(substitution_16) OVER w3 AS max_substitution_16_3
        ,MIN(substitution_16) OVER w3 AS min_substitution_16_3
        ,AVG(substitution_16) OVER w6 AS avg_substitution_16_6
        ,MAX(substitution_16) OVER w6 AS max_substitution_16_6
        ,MIN(substitution_16) OVER w6 AS min_substitution_16_6
        ,AVG(substitution_17) OVER w3 AS avg_substitution_17_3
        ,MAX(substitution_17) OVER w3 AS max_substitution_17_3
        ,MIN(substitution_17) OVER w3 AS min_substitution_17_3
        ,AVG(substitution_17) OVER w6 AS avg_substitution_17_6
        ,MAX(substitution_17) OVER w6 AS max_substitution_17_6
        ,MIN(substitution_17) OVER w6 AS min_substitution_17_6
        ,AVG(substitution_18) OVER w3 AS avg_substitution_18_3
        ,MAX(substitution_18) OVER w3 AS max_substitution_18_3
        ,MIN(substitution_18) OVER w3 AS min_substitution_18_3
        ,AVG(substitution_18) OVER w6 AS avg_substitution_18_6
        ,MAX(substitution_18) OVER w6 AS max_substitution_18_6
        ,MIN(substitution_18) OVER w6 AS min_substitution_18_6
        ,AVG(substitution_2) OVER w3 AS avg_substitution_2_3
        ,MAX(substitution_2) OVER w3 AS max_substitution_2_3
        ,MIN(substitution_2) OVER w3 AS min_substitution_2_3
        ,AVG(substitution_2) OVER w6 AS avg_substitution_2_6
        ,MAX(substitution_2) OVER w6 AS max_substitution_2_6
        ,MIN(substitution_2) OVER w6 AS min_substitution_2_6
        ,AVG(substitution_3) OVER w3 AS avg_substitution_3_3
        ,MAX(substitution_3) OVER w3 AS max_substitution_3_3
        ,MIN(substitution_3) OVER w3 AS min_substitution_3_3
        ,AVG(substitution_3) OVER w6 AS avg_substitution_3_6
        ,MAX(substitution_3) OVER w6 AS max_substitution_3_6
        ,MIN(substitution_3) OVER w6 AS min_substitution_3_6
        ,AVG(substitution_4) OVER w3 AS avg_substitution_4_3
        ,MAX(substitution_4) OVER w3 AS max_substitution_4_3
        ,MIN(substitution_4) OVER w3 AS min_substitution_4_3
        ,AVG(substitution_4) OVER w6 AS avg_substitution_4_6
        ,MAX(substitution_4) OVER w6 AS max_substitution_4_6
        ,MIN(substitution_4) OVER w6 AS min_substitution_4_6
        ,AVG(substitution_5) OVER w3 AS avg_substitution_5_3
        ,MAX(substitution_5) OVER w3 AS max_substitution_5_3
        ,MIN(substitution_5) OVER w3 AS min_substitution_5_3
        ,AVG(substitution_5) OVER w6 AS avg_substitution_5_6
        ,MAX(substitution_5) OVER w6 AS max_substitution_5_6
        ,MIN(substitution_5) OVER w6 AS min_substitution_5_6
        ,AVG(substitution_6) OVER w3 AS avg_substitution_6_3
        ,MAX(substitution_6) OVER w3 AS max_substitution_6_3
        ,MIN(substitution_6) OVER w3 AS min_substitution_6_3
        ,AVG(substitution_6) OVER w6 AS avg_substitution_6_6
        ,MAX(substitution_6) OVER w6 AS max_substitution_6_6
        ,MIN(substitution_6) OVER w6 AS min_substitution_6_6
        ,AVG(substitution_7) OVER w3 AS avg_substitution_7_3
        ,MAX(substitution_7) OVER w3 AS max_substitution_7_3
        ,MIN(substitution_7) OVER w3 AS min_substitution_7_3
        ,AVG(substitution_7) OVER w6 AS avg_substitution_7_6
        ,MAX(substitution_7) OVER w6 AS max_substitution_7_6
        ,MIN(substitution_7) OVER w6 AS min_substitution_7_6
        ,AVG(substitution_8) OVER w3 AS avg_substitution_8_3
        ,MAX(substitution_8) OVER w3 AS max_substitution_8_3
        ,MIN(substitution_8) OVER w3 AS min_substitution_8_3
        ,AVG(substitution_8) OVER w6 AS avg_substitution_8_6
        ,MAX(substitution_8) OVER w6 AS max_substitution_8_6
        ,MIN(substitution_8) OVER w6 AS min_substitution_8_6
        ,AVG(substitution_9) OVER w3 AS avg_substitution_9_3
        ,MAX(substitution_9) OVER w3 AS max_substitution_9_3
        ,MIN(substitution_9) OVER w3 AS min_substitution_9_3
        ,AVG(substitution_9) OVER w6 AS avg_substitution_9_6
        ,MAX(substitution_9) OVER w6 AS max_substitution_9_6
        ,MIN(substitution_9) OVER w6 AS min_substitution_9_6
        ,AVG(yellow_card) OVER w3 AS avg_yellow_card_3
        ,MAX(yellow_card) OVER w3 AS max_yellow_card_3
        ,MIN(yellow_card) OVER w3 AS min_yellow_card_3
        ,AVG(yellow_card) OVER w6 AS avg_yellow_card_6
        ,MAX(yellow_card) OVER w6 AS max_yellow_card_6
        ,MIN(yellow_card) OVER w6 AS min_yellow_card_6
        ,AVG(games_minutes) OVER w3 AS avg_games_minutes_3
        ,MAX(games_minutes) OVER w3 AS max_games_minutes_3
        ,MIN(games_minutes) OVER w3 AS min_games_minutes_3
        ,AVG(games_minutes) OVER w6 AS avg_games_minutes_6
        ,MAX(games_minutes) OVER w6 AS max_games_minutes_6
        ,MIN(games_minutes) OVER w6 AS min_games_minutes_6
        ,AVG(shots_total) OVER w3 AS avg_shots_total_3
        ,MAX(shots_total) OVER w3 AS max_shots_total_3
        ,MIN(shots_total) OVER w3 AS min_shots_total_3
        ,AVG(shots_total) OVER w6 AS avg_shots_total_6
        ,MAX(shots_total) OVER w6 AS max_shots_total_6
        ,MIN(shots_total) OVER w6 AS min_shots_total_6
        ,AVG(shots_on) OVER w3 AS avg_shots_on_3
        ,MAX(shots_on) OVER w3 AS max_shots_on_3
        ,MIN(shots_on) OVER w3 AS min_shots_on_3
        ,AVG(shots_on) OVER w6 AS avg_shots_on_6
        ,MAX(shots_on) OVER w6 AS max_shots_on_6
        ,MIN(shots_on) OVER w6 AS min_shots_on_6
        ,AVG(goals_total) OVER w3 AS avg_goals_total_3
        ,MAX(goals_total) OVER w3 AS max_goals_total_3
        ,MIN(goals_total) OVER w3 AS min_goals_total_3
        ,AVG(goals_total) OVER w6 AS avg_goals_total_6
        ,MAX(goals_total) OVER w6 AS max_goals_total_6
        ,MIN(goals_total) OVER w6 AS min_goals_total_6
        ,AVG(goals_conceded) OVER w3 AS avg_goals_conceded_3
        ,MAX(goals_conceded) OVER w3 AS max_goals_conceded_3
        ,MIN(goals_conceded) OVER w3 AS min_goals_conceded_3
        ,AVG(goals_conceded) OVER w6 AS avg_goals_conceded_6
        ,MAX(goals_conceded) OVER w6 AS max_goals_conceded_6
        ,MIN(goals_conceded) OVER w6 AS min_goals_conceded_6
        ,AVG(goals_assists) OVER w3 AS avg_goals_assists_3
        ,MAX(goals_assists) OVER w3 AS max_goals_assists_3
        ,MIN(goals_assists) OVER w3 AS min_goals_assists_3
        ,AVG(goals_assists) OVER w6 AS avg_goals_assists_6
        ,MAX(goals_assists) OVER w6 AS max_goals_assists_6
        ,MIN(goals_assists) OVER w6 AS min_goals_assists_6
        ,AVG(goals_saves) OVER w3 AS avg_goals_saves_3
        ,MAX(goals_saves) OVER w3 AS max_goals_saves_3
        ,MIN(goals_saves) OVER w3 AS min_goals_saves_3
        ,AVG(goals_saves) OVER w6 AS avg_goals_saves_6
        ,MAX(goals_saves) OVER w6 AS max_goals_saves_6
        ,MIN(goals_saves) OVER w6 AS min_goals_saves_6
        ,AVG(passes_total) OVER w3 AS avg_passes_total_3
        ,MAX(passes_total) OVER w3 AS max_passes_total_3
        ,MIN(passes_total) OVER w3 AS min_passes_total_3
        ,AVG(passes_total) OVER w6 AS avg_passes_total_6
        ,MAX(passes_total) OVER w6 AS max_passes_total_6
        ,MIN(passes_total) OVER w6 AS min_passes_total_6
        ,AVG(passes_key) OVER w3 AS avg_passes_key_3
        ,MAX(passes_key) OVER w3 AS max_passes_key_3
        ,MIN(passes_key) OVER w3 AS min_passes_key_3
        ,AVG(passes_key) OVER w6 AS avg_passes_key_6
        ,MAX(passes_key) OVER w6 AS max_passes_key_6
        ,MIN(passes_key) OVER w6 AS min_passes_key_6
        ,AVG(passes_accuracy) OVER w3 AS avg_passes_accuracy_3
        ,MAX(passes_accuracy) OVER w3 AS max_passes_accuracy_3
        ,MIN(passes_accuracy) OVER w3 AS min_passes_accuracy_3
        ,AVG(passes_accuracy) OVER w6 AS avg_passes_accuracy_6
        ,MAX(passes_accuracy) OVER w6 AS max_passes_accuracy_6
        ,MIN(passes_accuracy) OVER w6 AS min_passes_accuracy_6
        ,AVG(tackles_total) OVER w3 AS avg_tackles_total_3
        ,MAX(tackles_total) OVER w3 AS max_tackles_total_3
        ,MIN(tackles_total) OVER w3 AS min_tackles_total_3
        ,AVG(tackles_total) OVER w6 AS avg_tackles_total_6
        ,MAX(tackles_total) OVER w6 AS max_tackles_total_6
        ,MIN(tackles_total) OVER w6 AS min_tackles_total_6
        ,AVG(tackles_blocks) OVER w3 AS avg_tackles_blocks_3
        ,MAX(tackles_blocks) OVER w3 AS max_tackles_blocks_3
        ,MIN(tackles_blocks) OVER w3 AS min_tackles_blocks_3
        ,AVG(tackles_blocks) OVER w6 AS avg_tackles_blocks_6
        ,MAX(tackles_blocks) OVER w6 AS max_tackles_blocks_6
        ,MIN(tackles_blocks) OVER w6 AS min_tackles_blocks_6
        ,AVG(tackles_interceptions) OVER w3 AS avg_tackles_interceptions_3
        ,MAX(tackles_interceptions) OVER w3 AS max_tackles_interceptions_3
        ,MIN(tackles_interceptions) OVER w3 AS min_tackles_interceptions_3
        ,AVG(tackles_interceptions) OVER w6 AS avg_tackles_interceptions_6
        ,MAX(tackles_interceptions) OVER w6 AS max_tackles_interceptions_6
        ,MIN(tackles_interceptions) OVER w6 AS min_tackles_interceptions_6
        ,AVG(duels_total) OVER w3 AS avg_duels_total_3
        ,MAX(duels_total) OVER w3 AS max_duels_total_3
        ,MIN(duels_total) OVER w3 AS min_duels_total_3
        ,AVG(duels_total) OVER w6 AS avg_duels_total_6
        ,MAX(duels_total) OVER w6 AS max_duels_total_6
        ,MIN(duels_total) OVER w6 AS min_duels_total_6
        ,AVG(duels_won) OVER w3 AS avg_duels_won_3
        ,MAX(duels_won) OVER w3 AS max_duels_won_3
        ,MIN(duels_won) OVER w3 AS min_duels_won_3
        ,AVG(duels_won) OVER w6 AS avg_duels_won_6
        ,MAX(duels_won) OVER w6 AS max_duels_won_6
        ,MIN(duels_won) OVER w6 AS min_duels_won_6
        ,AVG(dribbles_attempts) OVER w3 AS avg_dribbles_attempts_3
        ,MAX(dribbles_attempts) OVER w3 AS max_dribbles_attempts_3
        ,MIN(dribbles_attempts) OVER w3 AS min_dribbles_attempts_3
        ,AVG(dribbles_attempts) OVER w6 AS avg_dribbles_attempts_6
        ,MAX(dribbles_attempts) OVER w6 AS max_dribbles_attempts_6
        ,MIN(dribbles_attempts) OVER w6 AS min_dribbles_attempts_6
        ,AVG(dribbles_success) OVER w3 AS avg_dribbles_success_3
        ,MAX(dribbles_success) OVER w3 AS max_dribbles_success_3
        ,MIN(dribbles_success) OVER w3 AS min_dribbles_success_3
        ,AVG(dribbles_success) OVER w6 AS avg_dribbles_success_6
        ,MAX(dribbles_success) OVER w6 AS max_dribbles_success_6
        ,MIN(dribbles_success) OVER w6 AS min_dribbles_success_6
        ,AVG(dribbles_past) OVER w3 AS avg_dribbles_past_3
        ,MAX(dribbles_past) OVER w3 AS max_dribbles_past_3
        ,MIN(dribbles_past) OVER w3 AS min_dribbles_past_3
        ,AVG(dribbles_past) OVER w6 AS avg_dribbles_past_6
        ,MAX(dribbles_past) OVER w6 AS max_dribbles_past_6
        ,MIN(dribbles_past) OVER w6 AS min_dribbles_past_6
        ,AVG(fouls_drawn) OVER w3 AS avg_fouls_drawn_3
        ,MAX(fouls_drawn) OVER w3 AS max_fouls_drawn_3
        ,MIN(fouls_drawn) OVER w3 AS min_fouls_drawn_3
        ,AVG(fouls_drawn) OVER w6 AS avg_fouls_drawn_6
        ,MAX(fouls_drawn) OVER w6 AS max_fouls_drawn_6
        ,MIN(fouls_drawn) OVER w6 AS min_fouls_drawn_6
        ,AVG(fouls_committed) OVER w3 AS avg_fouls_committed_3
        ,MAX(fouls_committed) OVER w3 AS max_fouls_committed_3
        ,MIN(fouls_committed) OVER w3 AS min_fouls_committed_3
        ,AVG(fouls_committed) OVER w6 AS avg_fouls_committed_6
        ,MAX(fouls_committed) OVER w6 AS max_fouls_committed_6
        ,MIN(fouls_committed) OVER w6 AS min_fouls_committed_6
        ,AVG(cards_yellow) OVER w3 AS avg_cards_yellow_3
        ,MAX(cards_yellow) OVER w3 AS max_cards_yellow_3
        ,MIN(cards_yellow) OVER w3 AS min_cards_yellow_3
        ,AVG(cards_yellow) OVER w6 AS avg_cards_yellow_6
        ,MAX(cards_yellow) OVER w6 AS max_cards_yellow_6
        ,MIN(cards_yellow) OVER w6 AS min_cards_yellow_6
        ,AVG(cards_red) OVER w3 AS avg_cards_red_3
        ,MAX(cards_red) OVER w3 AS max_cards_red_3
        ,MIN(cards_red) OVER w3 AS min_cards_red_3
        ,AVG(cards_red) OVER w6 AS avg_cards_red_6
        ,MAX(cards_red) OVER w6 AS max_cards_red_6
        ,MIN(cards_red) OVER w6 AS min_cards_red_6
        ,AVG(penalty_won) OVER w3 AS avg_penalty_won_3
        ,MAX(penalty_won) OVER w3 AS max_penalty_won_3
        ,MIN(penalty_won) OVER w3 AS min_penalty_won_3
        ,AVG(penalty_won) OVER w6 AS avg_penalty_won_6
        ,MAX(penalty_won) OVER w6 AS max_penalty_won_6
        ,MIN(penalty_won) OVER w6 AS min_penalty_won_6
        ,AVG(penalty_commited) OVER w3 AS avg_penalty_commited_3
        ,MAX(penalty_commited) OVER w3 AS max_penalty_commited_3
        ,MIN(penalty_commited) OVER w3 AS min_penalty_commited_3
        ,AVG(penalty_commited) OVER w6 AS avg_penalty_commited_6
        ,MAX(penalty_commited) OVER w6 AS max_penalty_commited_6
        ,MIN(penalty_commited) OVER w6 AS min_penalty_commited_6
        ,AVG(penalty_scored) OVER w3 AS avg_penalty_scored_3
        ,MAX(penalty_scored) OVER w3 AS max_penalty_scored_3
        ,MIN(penalty_scored) OVER w3 AS min_penalty_scored_3
        ,AVG(penalty_scored) OVER w6 AS avg_penalty_scored_6
        ,MAX(penalty_scored) OVER w6 AS max_penalty_scored_6
        ,MIN(penalty_scored) OVER w6 AS min_penalty_scored_6
        ,AVG(penalty_missed) OVER w3 AS avg_penalty_missed_3
        ,MAX(penalty_missed) OVER w3 AS max_penalty_missed_3
        ,MIN(penalty_missed) OVER w3 AS min_penalty_missed_3
        ,AVG(penalty_missed) OVER w6 AS avg_penalty_missed_6
        ,MAX(penalty_missed) OVER w6 AS max_penalty_missed_6
        ,MIN(penalty_missed) OVER w6 AS min_penalty_missed_6
        ,AVG(penalty_saved) OVER w3 AS avg_penalty_saved_3
        ,MAX(penalty_saved) OVER w3 AS max_penalty_saved_3
        ,MIN(penalty_saved) OVER w3 AS min_penalty_saved_3
        ,AVG(penalty_saved) OVER w6 AS avg_penalty_saved_6
        ,MAX(penalty_saved) OVER w6 AS max_penalty_saved_6
        ,MIN(penalty_saved) OVER w6 AS min_penalty_saved_6

    FROM transformed_prod_match_summary t1

    WINDOW
        w3 AS (
            PARTITION BY team_id
            ORDER BY date, fixture_id
            ROWS BETWEEN 3 PRECEDING AND 1 PRECEDING
        ),
        w6 AS (
            PARTITION BY team_id
            ORDER BY date, fixture_id
            ROWS BETWEEN 6 PRECEDING AND 1 PRECEDING
        )
)
SELECT *
FROM metrics;




-- Last Union
DROP TABLE IF EXISTS transformed_prod_match_summary_total_features;
CREATE TEMP TABLE transformed_prod_match_summary_total_features AS
SELECT
t1.*
-- ,t2.date_1
-- ,t2.date_2
-- ,t2.date_3
-- ,t2.date_4
-- ,t2.date_5
-- ,t2.date_6
-- ,t2.date_7
,t2.lag_goals_1
,t2.lag_goals_2
,t2.lag_goals_3
,t2.lag_goals_4
,t2.lag_is_winner_1
,t2.lag_is_winner_2
,t2.lag_is_winner_3
,t2.lag_is_winner_4
,t2.lag_is_home_1
,t2.lag_is_home_2
,t2.lag_is_home_3
,t2.lag_is_home_4
,t2.lag_shots_on_goal_1
,t2.lag_shots_on_goal_2
,t2.lag_shots_on_goal_3
,t2.lag_shots_on_goal_4
,t2.lag_shots_off_goal_1
,t2.lag_shots_off_goal_2
,t2.lag_shots_off_goal_3
,t2.lag_shots_off_goal_4
,t2.lag_total_shots_1
,t2.lag_total_shots_2
,t2.lag_total_shots_3
,t2.lag_total_shots_4
,t2.lag_blocked_shots_1
,t2.lag_blocked_shots_2
,t2.lag_blocked_shots_3
,t2.lag_blocked_shots_4
,t2.lag_shots_insidebox_1
,t2.lag_shots_insidebox_2
,t2.lag_shots_insidebox_3
,t2.lag_shots_insidebox_4
,t2.lag_shots_outsidebox_1
,t2.lag_shots_outsidebox_2
,t2.lag_shots_outsidebox_3
,t2.lag_shots_outsidebox_4
,t2.lag_fouls_1
,t2.lag_fouls_2
,t2.lag_fouls_3
,t2.lag_fouls_4
,t2.lag_corner_kicks_1
,t2.lag_corner_kicks_2
,t2.lag_corner_kicks_3
,t2.lag_corner_kicks_4
,t2.lag_offsides_1
,t2.lag_offsides_2
,t2.lag_offsides_3
,t2.lag_offsides_4
,t2.lag_ball_possession_1
,t2.lag_ball_possession_2
,t2.lag_ball_possession_3
,t2.lag_ball_possession_4
,t2.lag_yellow_cards_1
,t2.lag_yellow_cards_2
,t2.lag_yellow_cards_3
,t2.lag_yellow_cards_4
,t2.lag_red_cards_1
,t2.lag_red_cards_2
,t2.lag_red_cards_3
,t2.lag_red_cards_4
,t2.lag_goalkeeper_saves_1
,t2.lag_goalkeeper_saves_2
,t2.lag_goalkeeper_saves_3
,t2.lag_goalkeeper_saves_4
,t2.lag_total_passes_1
,t2.lag_total_passes_2
,t2.lag_total_passes_3
,t2.lag_total_passes_4
,t2.lag_passes_accurate_1
,t2.lag_passes_accurate_2
,t2.lag_passes_accurate_3
,t2.lag_passes_accurate_4
,t2.lag_passes_perc_1
,t2.lag_passes_perc_2
,t2.lag_passes_perc_3
,t2.lag_passes_perc_4
,t2.lag_goals_prevented_1
,t2.lag_goals_prevented_2
,t2.lag_goals_prevented_3
,t2.lag_goals_prevented_4
,t2.lag_card_reviewed_1
,t2.lag_card_reviewed_2
,t2.lag_card_reviewed_3
,t2.lag_card_reviewed_4
,t2.lag_card_upgrade_1
,t2.lag_card_upgrade_2
,t2.lag_card_upgrade_3
,t2.lag_card_upgrade_4
,t2.lag_goal_cancelled_1
,t2.lag_goal_cancelled_2
,t2.lag_goal_cancelled_3
,t2.lag_goal_cancelled_4
,t2.lag_goal_confirmed_1
,t2.lag_goal_confirmed_2
,t2.lag_goal_confirmed_3
,t2.lag_goal_confirmed_4
,t2.lag_goal_disallowed_1
,t2.lag_goal_disallowed_2
,t2.lag_goal_disallowed_3
,t2.lag_goal_disallowed_4
,t2.lag_goal_disallowed_foul_1
,t2.lag_goal_disallowed_foul_2
,t2.lag_goal_disallowed_foul_3
,t2.lag_goal_disallowed_foul_4
,t2.lag_goal_disallowed_handball_1
,t2.lag_goal_disallowed_handball_2
,t2.lag_goal_disallowed_handball_3
,t2.lag_goal_disallowed_handball_4
,t2.lag_goal_disallowed_offside_1
,t2.lag_goal_disallowed_offside_2
,t2.lag_goal_disallowed_offside_3
,t2.lag_goal_disallowed_offside_4
,t2.lag_missed_penalty_1
,t2.lag_missed_penalty_2
,t2.lag_missed_penalty_3
,t2.lag_missed_penalty_4
,t2.lag_normal_goal_1
,t2.lag_normal_goal_2
,t2.lag_normal_goal_3
,t2.lag_normal_goal_4
,t2.lag_own_goal_1
,t2.lag_own_goal_2
,t2.lag_own_goal_3
,t2.lag_own_goal_4
,t2.lag_penalty_1
,t2.lag_penalty_2
,t2.lag_penalty_3
,t2.lag_penalty_4
,t2.lag_penalty_awarded_1
,t2.lag_penalty_awarded_2
,t2.lag_penalty_awarded_3
,t2.lag_penalty_awarded_4
,t2.lag_penalty_cancelled_1
,t2.lag_penalty_cancelled_2
,t2.lag_penalty_cancelled_3
,t2.lag_penalty_cancelled_4
,t2.lag_penalty_confirmed_1
,t2.lag_penalty_confirmed_2
,t2.lag_penalty_confirmed_3
,t2.lag_penalty_confirmed_4
,t2.lag_red_card_1
,t2.lag_red_card_2
,t2.lag_red_card_3
,t2.lag_red_card_4
,t2.lag_red_card_cancelled_1
,t2.lag_red_card_cancelled_2
,t2.lag_red_card_cancelled_3
,t2.lag_red_card_cancelled_4
,t2.lag_substitution_1_1
,t2.lag_substitution_1_2
,t2.lag_substitution_1_3
,t2.lag_substitution_1_4
,t2.lag_substitution_10_1
,t2.lag_substitution_10_2
,t2.lag_substitution_10_3
,t2.lag_substitution_10_4
,t2.lag_substitution_11_1
,t2.lag_substitution_11_2
,t2.lag_substitution_11_3
,t2.lag_substitution_11_4
,t2.lag_substitution_12_1
,t2.lag_substitution_12_2
,t2.lag_substitution_12_3
,t2.lag_substitution_12_4
,t2.lag_substitution_13_1
,t2.lag_substitution_13_2
,t2.lag_substitution_13_3
,t2.lag_substitution_13_4
,t2.lag_substitution_14_1
,t2.lag_substitution_14_2
,t2.lag_substitution_14_3
,t2.lag_substitution_14_4
,t2.lag_substitution_15_1
,t2.lag_substitution_15_2
,t2.lag_substitution_15_3
,t2.lag_substitution_15_4
,t2.lag_substitution_16_1
,t2.lag_substitution_16_2
,t2.lag_substitution_16_3
,t2.lag_substitution_16_4
,t2.lag_substitution_17_1
,t2.lag_substitution_17_2
,t2.lag_substitution_17_3
,t2.lag_substitution_17_4
,t2.lag_substitution_18_1
,t2.lag_substitution_18_2
,t2.lag_substitution_18_3
,t2.lag_substitution_18_4
,t2.lag_substitution_2_1
,t2.lag_substitution_2_2
,t2.lag_substitution_2_3
,t2.lag_substitution_2_4
,t2.lag_substitution_3_1
,t2.lag_substitution_3_2
,t2.lag_substitution_3_3
,t2.lag_substitution_3_4
,t2.lag_substitution_4_1
,t2.lag_substitution_4_2
,t2.lag_substitution_4_3
,t2.lag_substitution_4_4
,t2.lag_substitution_5_1
,t2.lag_substitution_5_2
,t2.lag_substitution_5_3
,t2.lag_substitution_5_4
,t2.lag_substitution_6_1
,t2.lag_substitution_6_2
,t2.lag_substitution_6_3
,t2.lag_substitution_6_4
,t2.lag_substitution_7_1
,t2.lag_substitution_7_2
,t2.lag_substitution_7_3
,t2.lag_substitution_7_4
,t2.lag_substitution_8_1
,t2.lag_substitution_8_2
,t2.lag_substitution_8_3
,t2.lag_substitution_8_4
,t2.lag_substitution_9_1
,t2.lag_substitution_9_2
,t2.lag_substitution_9_3
,t2.lag_substitution_9_4
,t2.lag_yellow_card_1
,t2.lag_yellow_card_2
,t2.lag_yellow_card_3
,t2.lag_yellow_card_4
,t2.lag_games_minutes_1
,t2.lag_games_minutes_2
,t2.lag_games_minutes_3
,t2.lag_games_minutes_4
,t2.lag_shots_total_1
,t2.lag_shots_total_2
,t2.lag_shots_total_3
,t2.lag_shots_total_4
,t2.lag_shots_on_1
,t2.lag_shots_on_2
,t2.lag_shots_on_3
,t2.lag_shots_on_4
,t2.lag_goals_total_1
,t2.lag_goals_total_2
,t2.lag_goals_total_3
,t2.lag_goals_total_4
,t2.lag_goals_conceded_1
,t2.lag_goals_conceded_2
,t2.lag_goals_conceded_3
,t2.lag_goals_conceded_4
,t2.lag_goals_assists_1
,t2.lag_goals_assists_2
,t2.lag_goals_assists_3
,t2.lag_goals_assists_4
,t2.lag_goals_saves_1
,t2.lag_goals_saves_2
,t2.lag_goals_saves_3
,t2.lag_goals_saves_4
,t2.lag_passes_total_1
,t2.lag_passes_total_2
,t2.lag_passes_total_3
,t2.lag_passes_total_4
,t2.lag_passes_key_1
,t2.lag_passes_key_2
,t2.lag_passes_key_3
,t2.lag_passes_key_4
,t2.lag_passes_accuracy_1
,t2.lag_passes_accuracy_2
,t2.lag_passes_accuracy_3
,t2.lag_passes_accuracy_4
,t2.lag_tackles_total_1
,t2.lag_tackles_total_2
,t2.lag_tackles_total_3
,t2.lag_tackles_total_4
,t2.lag_tackles_blocks_1
,t2.lag_tackles_blocks_2
,t2.lag_tackles_blocks_3
,t2.lag_tackles_blocks_4
,t2.lag_tackles_interceptions_1
,t2.lag_tackles_interceptions_2
,t2.lag_tackles_interceptions_3
,t2.lag_tackles_interceptions_4
,t2.lag_duels_total_1
,t2.lag_duels_total_2
,t2.lag_duels_total_3
,t2.lag_duels_total_4
,t2.lag_duels_won_1
,t2.lag_duels_won_2
,t2.lag_duels_won_3
,t2.lag_duels_won_4
,t2.lag_dribbles_attempts_1
,t2.lag_dribbles_attempts_2
,t2.lag_dribbles_attempts_3
,t2.lag_dribbles_attempts_4
,t2.lag_dribbles_success_1
,t2.lag_dribbles_success_2
,t2.lag_dribbles_success_3
,t2.lag_dribbles_success_4
,t2.lag_dribbles_past_1
,t2.lag_dribbles_past_2
,t2.lag_dribbles_past_3
,t2.lag_dribbles_past_4
,t2.lag_fouls_drawn_1
,t2.lag_fouls_drawn_2
,t2.lag_fouls_drawn_3
,t2.lag_fouls_drawn_4
,t2.lag_fouls_committed_1
,t2.lag_fouls_committed_2
,t2.lag_fouls_committed_3
,t2.lag_fouls_committed_4
,t2.lag_cards_yellow_1
,t2.lag_cards_yellow_2
,t2.lag_cards_yellow_3
,t2.lag_cards_yellow_4
,t2.lag_cards_red_1
,t2.lag_cards_red_2
,t2.lag_cards_red_3
,t2.lag_cards_red_4
,t2.lag_penalty_won_1
,t2.lag_penalty_won_2
,t2.lag_penalty_won_3
,t2.lag_penalty_won_4
,t2.lag_penalty_commited_1
,t2.lag_penalty_commited_2
,t2.lag_penalty_commited_3
,t2.lag_penalty_commited_4
,t2.lag_penalty_scored_1
,t2.lag_penalty_scored_2
,t2.lag_penalty_scored_3
,t2.lag_penalty_scored_4
,t2.lag_penalty_missed_1
,t2.lag_penalty_missed_2
,t2.lag_penalty_missed_3
,t2.lag_penalty_missed_4
,t2.lag_penalty_saved_1
,t2.lag_penalty_saved_2
,t2.lag_penalty_saved_3
,t2.lag_penalty_saved_4
,t3.shots_on_goal_slope_3::real
,t3.shots_off_goal_slope_3::real
,t3.total_shots_slope_3::real
,t3.blocked_shots_slope_3::real
,t3.shots_insidebox_slope_3::real
,t3.shots_outsidebox_slope_3::real
,t3.fouls_slope_3::real
,t3.corner_kicks_slope_3::real
,t3.offsides_slope_3::real
,t3.ball_possession_slope_3::real
,t3.yellow_cards_slope_3::real
,t3.red_cards_slope_3::real
,t3.goalkeeper_saves_slope_3::real
,t3.total_passes_slope_3::real
,t3.passes_accurate_slope_3::real
,t3.passes_perc_slope_3::real
,t3.goals_prevented_slope_3::real
,t3.card_reviewed_slope_3::real
,t3.card_upgrade_slope_3::real
,t3.goal_cancelled_slope_3::real
,t3.goal_confirmed_slope_3::real
,t3.goal_disallowed_slope_3::real
,t3.goal_disallowed_foul_slope_3::real
,t3.goal_disallowed_handball_slope_3::real
,t3.goal_disallowed_offside_slope_3::real
,t3.missed_penalty_slope_3::real
,t3.normal_goal_slope_3::real
,t3.own_goal_slope_3::real
,t3.penalty_slope_3::real
,t3.penalty_awarded_slope_3::real
,t3.penalty_cancelled_slope_3::real
,t3.penalty_confirmed_slope_3::real
,t3.red_card_slope_3::real
,t3.red_card_cancelled_slope_3::real
,t3.substitution_1_slope_3::real
,t3.substitution_10_slope_3::real
,t3.substitution_11_slope_3::real
,t3.substitution_12_slope_3::real
,t3.substitution_13_slope_3::real
,t3.substitution_14_slope_3::real
,t3.substitution_15_slope_3::real
,t3.substitution_16_slope_3::real
,t3.substitution_17_slope_3::real
,t3.substitution_18_slope_3::real
,t3.substitution_2_slope_3::real
,t3.substitution_3_slope_3::real
,t3.substitution_4_slope_3::real
,t3.substitution_5_slope_3::real
,t3.substitution_6_slope_3::real
,t3.substitution_7_slope_3::real
,t3.substitution_8_slope_3::real
,t3.substitution_9_slope_3::real
,t3.yellow_card_slope_3::real
,t3.games_minutes_slope_3::real
,t3.shots_total_slope_3::real
,t3.shots_on_slope_3::real
,t3.goals_total_slope_3::real
,t3.goals_conceded_slope_3::real
,t3.goals_assists_slope_3::real
,t3.goals_saves_slope_3::real
,t3.passes_total_slope_3::real
,t3.passes_key_slope_3::real
,t3.passes_accuracy_slope_3::real
,t3.tackles_total_slope_3::real
,t3.tackles_blocks_slope_3::real
,t3.tackles_interceptions_slope_3::real
,t3.duels_total_slope_3::real
,t3.duels_won_slope_3::real
,t3.dribbles_attempts_slope_3::real
,t3.dribbles_success_slope_3::real
,t3.dribbles_past_slope_3::real
,t3.fouls_drawn_slope_3::real
,t3.fouls_committed_slope_3::real
,t3.cards_yellow_slope_3::real
,t3.cards_red_slope_3::real
,t3.penalty_won_slope_3::real
,t3.penalty_commited_slope_3::real
,t3.penalty_scored_slope_3::real
,t3.penalty_missed_slope_3::real
,t3.penalty_saved_slope_3::real
,t3.goals_slope_t3
,t4.sum_shots_on_goal_3
,t4.sum_shots_off_goal_3
,t4.sum_total_shots_3
,t4.sum_blocked_shots_3
,t4.sum_shots_insidebox_3
,t4.sum_shots_outsidebox_3
,t4.sum_fouls_3
,t4.sum_corner_kicks_3
,t4.sum_offsides_3
,t4.sum_ball_possession_3
,t4.sum_yellow_cards_3
,t4.sum_red_cards_3
,t4.sum_goalkeeper_saves_3
,t4.sum_total_passes_3
,t4.sum_passes_accurate_3
,t4.sum_passes_perc_3
,t4.sum_goals_prevented_3
,t4.sum_card_reviewed_3
,t4.sum_card_upgrade_3
,t4.sum_goal_cancelled_3
,t4.sum_goal_confirmed_3
,t4.sum_goal_disallowed_3
,t4.sum_goal_disallowed_foul_3
,t4.sum_goal_disallowed_handball_3
,t4.sum_goal_disallowed_offside_3
,t4.sum_missed_penalty_3
,t4.sum_normal_goal_3
,t4.sum_own_goal_3
,t4.sum_penalty_3
,t4.sum_penalty_awarded_3
,t4.sum_penalty_cancelled_3
,t4.sum_penalty_confirmed_3
,t4.sum_red_card_3
,t4.sum_red_card_cancelled_3
,t4.sum_substitution_1_3
,t4.sum_substitution_10_3
,t4.sum_substitution_11_3
,t4.sum_substitution_12_3
,t4.sum_substitution_13_3
,t4.sum_substitution_14_3
,t4.sum_substitution_15_3
,t4.sum_substitution_16_3
,t4.sum_substitution_17_3
,t4.sum_substitution_18_3
,t4.sum_substitution_2_3
,t4.sum_substitution_3_3
,t4.sum_substitution_4_3
,t4.sum_substitution_5_3
,t4.sum_substitution_6_3
,t4.sum_substitution_7_3
,t4.sum_substitution_8_3
,t4.sum_substitution_9_3
,t4.sum_yellow_card_3
,t4.sum_games_minutes_3
,t4.sum_shots_total_3
,t4.sum_shots_on_3
,t4.sum_goals_total_3
,t4.sum_goals_conceded_3
,t4.sum_goals_assists_3
,t4.sum_goals_saves_3
,t4.sum_passes_total_3
,t4.sum_passes_key_3
,t4.sum_passes_accuracy_3
,t4.sum_tackles_total_3
,t4.sum_tackles_blocks_3
,t4.sum_tackles_interceptions_3
,t4.sum_duels_total_3
,t4.sum_duels_won_3
,t4.sum_dribbles_attempts_3
,t4.sum_dribbles_success_3
,t4.sum_dribbles_past_3
,t4.sum_fouls_drawn_3
,t4.sum_fouls_committed_3
,t4.sum_cards_yellow_3
,t4.sum_cards_red_3
,t4.sum_penalty_won_3
,t4.sum_penalty_commited_3
,t4.sum_penalty_scored_3
,t4.sum_penalty_missed_3
,t4.sum_penalty_saved_3
,t4.avg_shots_on_goal_3::real
,t4.max_shots_on_goal_3::real
,t4.min_shots_on_goal_3::real
,t4.avg_shots_off_goal_3::real
,t4.max_shots_off_goal_3::real
,t4.min_shots_off_goal_3::real
,t4.avg_total_shots_3::real
,t4.max_total_shots_3::real
,t4.min_total_shots_3::real
,t4.avg_blocked_shots_3::real
,t4.max_blocked_shots_3::real
,t4.min_blocked_shots_3::real
,t4.avg_shots_insidebox_3::real
,t4.max_shots_insidebox_3::real
,t4.min_shots_insidebox_3::real
,t4.avg_shots_outsidebox_3::real
,t4.max_shots_outsidebox_3::real
,t4.min_shots_outsidebox_3::real
,t4.avg_fouls_3::real
,t4.max_fouls_3::real
,t4.min_fouls_3::real
,t4.avg_corner_kicks_3::real
,t4.max_corner_kicks_3::real
,t4.min_corner_kicks_3::real
,t4.avg_offsides_3::real
,t4.max_offsides_3::real
,t4.min_offsides_3::real
,t4.avg_ball_possession_3::real
,t4.max_ball_possession_3::real
,t4.min_ball_possession_3::real
,t4.avg_yellow_cards_3::real
,t4.max_yellow_cards_3::real
,t4.min_yellow_cards_3::real
,t4.avg_red_cards_3::real
,t4.max_red_cards_3::real
,t4.min_red_cards_3::real
,t4.avg_goalkeeper_saves_3::real
,t4.max_goalkeeper_saves_3::real
,t4.min_goalkeeper_saves_3::real
,t4.avg_total_passes_3::real
,t4.max_total_passes_3::real
,t4.min_total_passes_3::real
,t4.avg_passes_accurate_3::real
,t4.max_passes_accurate_3::real
,t4.min_passes_accurate_3::real
,t4.avg_passes_perc_3::real
,t4.max_passes_perc_3::real
,t4.min_passes_perc_3::real
,t4.avg_goals_prevented_3::real
,t4.max_goals_prevented_3::real
,t4.min_goals_prevented_3::real
,t4.avg_card_reviewed_3::real
,t4.max_card_reviewed_3::real
,t4.min_card_reviewed_3::real
,t4.avg_card_upgrade_3::real
,t4.max_card_upgrade_3::real
,t4.min_card_upgrade_3::real
,t4.avg_goal_cancelled_3::real
,t4.max_goal_cancelled_3::real
,t4.min_goal_cancelled_3::real
,t4.avg_goal_confirmed_3::real
,t4.max_goal_confirmed_3::real
,t4.min_goal_confirmed_3::real
,t4.avg_goal_disallowed_3::real
,t4.max_goal_disallowed_3::real
,t4.min_goal_disallowed_3::real
,t4.avg_goal_disallowed_foul_3::real
,t4.max_goal_disallowed_foul_3::real
,t4.min_goal_disallowed_foul_3::real
,t4.avg_goal_disallowed_handball_3::real
,t4.max_goal_disallowed_handball_3::real
,t4.min_goal_disallowed_handball_3::real
,t4.avg_goal_disallowed_offside_3::real
,t4.max_goal_disallowed_offside_3::real
,t4.min_goal_disallowed_offside_3::real
,t4.avg_missed_penalty_3::real
,t4.max_missed_penalty_3::real
,t4.min_missed_penalty_3::real
,t4.avg_normal_goal_3::real
,t4.max_normal_goal_3::real
,t4.min_normal_goal_3::real
,t4.avg_own_goal_3::real
,t4.max_own_goal_3::real
,t4.min_own_goal_3::real
,t4.avg_penalty_3::real
,t4.max_penalty_3::real
,t4.min_penalty_3::real
,t4.avg_penalty_awarded_3::real
,t4.max_penalty_awarded_3::real
,t4.min_penalty_awarded_3::real
,t4.avg_penalty_cancelled_3::real
,t4.max_penalty_cancelled_3::real
,t4.min_penalty_cancelled_3::real
,t4.avg_penalty_confirmed_3::real
,t4.max_penalty_confirmed_3::real
,t4.min_penalty_confirmed_3::real
,t4.avg_red_card_3::real
,t4.max_red_card_3::real
,t4.min_red_card_3::real
,t4.avg_red_card_cancelled_3::real
,t4.max_red_card_cancelled_3::real
,t4.min_red_card_cancelled_3::real
,t4.avg_substitution_1_3::real
,t4.max_substitution_1_3::real
,t4.min_substitution_1_3::real
,t4.avg_substitution_10_3::real
,t4.max_substitution_10_3::real
,t4.min_substitution_10_3::real
,t4.avg_substitution_11_3::real
,t4.max_substitution_11_3::real
,t4.min_substitution_11_3::real
,t4.avg_substitution_12_3::real
,t4.max_substitution_12_3::real
,t4.min_substitution_12_3::real
,t4.avg_substitution_13_3::real
,t4.max_substitution_13_3::real
,t4.min_substitution_13_3::real
,t4.avg_substitution_14_3::real
,t4.max_substitution_14_3::real
,t4.min_substitution_14_3::real
,t4.avg_substitution_15_3::real
,t4.max_substitution_15_3::real
,t4.min_substitution_15_3::real
,t4.avg_substitution_16_3::real
,t4.max_substitution_16_3::real
,t4.min_substitution_16_3::real
,t4.avg_substitution_17_3::real
,t4.max_substitution_17_3::real
,t4.min_substitution_17_3::real
,t4.avg_substitution_18_3::real
,t4.max_substitution_18_3::real
,t4.min_substitution_18_3::real
,t4.avg_substitution_2_3::real
,t4.max_substitution_2_3::real
,t4.min_substitution_2_3::real
,t4.avg_substitution_3_3::real
,t4.max_substitution_3_3::real
,t4.min_substitution_3_3::real
,t4.avg_substitution_4_3::real
,t4.max_substitution_4_3::real
,t4.min_substitution_4_3::real
,t4.avg_substitution_5_3::real
,t4.max_substitution_5_3::real
,t4.min_substitution_5_3::real
,t4.avg_substitution_6_3::real
,t4.max_substitution_6_3::real
,t4.min_substitution_6_3::real
,t4.avg_substitution_7_3::real
,t4.max_substitution_7_3::real
,t4.min_substitution_7_3::real
,t4.avg_substitution_8_3::real
,t4.max_substitution_8_3::real
,t4.min_substitution_8_3::real
,t4.avg_substitution_9_3::real
,t4.max_substitution_9_3::real
,t4.min_substitution_9_3::real
,t4.avg_yellow_card_3::real
,t4.max_yellow_card_3::real
,t4.min_yellow_card_3::real
,t4.avg_games_minutes_3::real
,t4.max_games_minutes_3::real
,t4.min_games_minutes_3::real
,t4.avg_shots_total_3::real
,t4.max_shots_total_3::real
,t4.min_shots_total_3::real
,t4.avg_shots_on_3::real
,t4.max_shots_on_3::real
,t4.min_shots_on_3::real
,t4.avg_goals_total_3::real
,t4.max_goals_total_3::real
,t4.min_goals_total_3::real
,t4.avg_goals_conceded_3::real
,t4.max_goals_conceded_3::real
,t4.min_goals_conceded_3::real
,t4.avg_goals_assists_3::real
,t4.max_goals_assists_3::real
,t4.min_goals_assists_3::real
,t4.avg_goals_saves_3::real
,t4.max_goals_saves_3::real
,t4.min_goals_saves_3::real
,t4.avg_passes_total_3::real
,t4.max_passes_total_3::real
,t4.min_passes_total_3::real
,t4.avg_passes_key_3::real
,t4.max_passes_key_3::real
,t4.min_passes_key_3::real
,t4.avg_passes_accuracy_3::real
,t4.max_passes_accuracy_3::real
,t4.min_passes_accuracy_3::real
,t4.avg_tackles_total_3::real
,t4.max_tackles_total_3::real
,t4.min_tackles_total_3::real
,t4.avg_tackles_blocks_3::real
,t4.max_tackles_blocks_3::real
,t4.min_tackles_blocks_3::real
,t4.avg_tackles_interceptions_3::real
,t4.max_tackles_interceptions_3::real
,t4.min_tackles_interceptions_3::real
,t4.avg_duels_total_3::real
,t4.max_duels_total_3::real
,t4.min_duels_total_3::real
,t4.avg_duels_won_3::real
,t4.max_duels_won_3::real
,t4.min_duels_won_3::real
,t4.avg_dribbles_attempts_3::real
,t4.max_dribbles_attempts_3::real
,t4.min_dribbles_attempts_3::real
,t4.avg_dribbles_success_3::real
,t4.max_dribbles_success_3::real
,t4.min_dribbles_success_3::real
,t4.avg_dribbles_past_3::real
,t4.max_dribbles_past_3::real
,t4.min_dribbles_past_3::real
,t4.avg_fouls_drawn_3::real
,t4.max_fouls_drawn_3::real
,t4.min_fouls_drawn_3::real
,t4.avg_fouls_committed_3::real
,t4.max_fouls_committed_3::real
,t4.min_fouls_committed_3::real
,t4.avg_cards_yellow_3::real
,t4.max_cards_yellow_3::real
,t4.min_cards_yellow_3::real
,t4.avg_cards_red_3::real
,t4.max_cards_red_3::real
,t4.min_cards_red_3::real
,t4.avg_penalty_won_3::real
,t4.max_penalty_won_3::real
,t4.min_penalty_won_3::real
,t4.avg_penalty_commited_3::real
,t4.max_penalty_commited_3::real
,t4.min_penalty_commited_3::real
,t4.avg_penalty_scored_3::real
,t4.max_penalty_scored_3::real
,t4.min_penalty_scored_3::real
,t4.avg_penalty_missed_3::real
,t4.max_penalty_missed_3::real
,t4.min_penalty_missed_3::real
,t4.avg_penalty_saved_3::real
,t4.max_penalty_saved_3::real
,t4.min_penalty_saved_3::real
FROM transformed_prod_match_summary t1
LEFT JOIN transformed_prod_match_summary_lags t2 ON t1.fixture_id = t2.fixture_id AND t1.team_id = t2.team_id
LEFT JOIN transformed_prod_match_summary_tendencies t3 ON t1.fixture_id = t3.fixture_id AND t1.team_id = t3.team_id
LEFT JOIN transformed_prod_match_summary_sum_avg_max_min t4 ON t1.fixture_id = t4.fixture_id AND t1.team_id = t4.team_id
;



DROP TABLE IF EXISTS prod_match_summary_home_away_teams_id;
CREATE TEMP TABLE prod_match_summary_home_away_teams_id AS
WITH  matches_numbered_part_1 AS
(
    SELECT *
    FROM transformed_prod_match_summary
    WHERE is_home = 1
), matches_numbered_part_2 AS
(
    SELECT *
    FROM transformed_prod_match_summary
    WHERE is_home = 0
)
SELECT
t1.fixture_id
,t1.date
,t1.venue_id
,t1.venue_name
,t1.status_elapsed
,t1.status_extra
,t1.league_id
,t1.league_season
,t1.team_id home_team_id
,t2.team_id away_team_id
, 
    CASE
        WHEN t1.is_winner = TRUE THEN 1
        WHEN t2.is_winner = TRUE THEN 2
        WHEN t1.is_winner = FALSE AND t2.is_winner = FALSE THEN 0
    END target
FROM matches_numbered_part_1 t1
INNER JOIN matches_numbered_part_2 t2 ON t1.fixture_id = t2.fixture_id
;

DROP TABLE IF EXISTS transformed_prod_match_summary_full_league_features;
CREATE TABLE transformed_prod_match_summary_full_league_features AS
SELECT
t1.*
,t2.lag_goals_1 home_goals_lag_1
,t2.lag_goals_2 home_goals_lag_2
,t2.lag_goals_3 home_goals_lag_3
,t2.lag_goals_4 home_goals_lag_4
,t2.lag_is_winner_1 home_is_winner_lag_1
,t2.lag_is_winner_2 home_is_winner_lag_2
,t2.lag_is_winner_3 home_is_winner_lag_3
,t2.lag_is_winner_4 home_is_winner_lag_4
,t2.lag_is_home_1 home_is_home_lag_1
,t2.lag_is_home_2 home_is_home_lag_2
,t2.lag_is_home_3 home_is_home_lag_3
,t2.lag_is_home_4 home_is_home_lag_4
,t2.lag_shots_on_goal_1 home_shots_on_goal_lag_1
,t2.lag_shots_on_goal_2 home_shots_on_goal_lag_2
,t2.lag_shots_on_goal_3 home_shots_on_goal_lag_3
,t2.lag_shots_on_goal_4 home_shots_on_goal_lag_4
,t2.lag_shots_off_goal_1 home_shots_off_goal_lag_1
,t2.lag_shots_off_goal_2 home_shots_off_goal_lag_2
,t2.lag_shots_off_goal_3 home_shots_off_goal_lag_3
,t2.lag_shots_off_goal_4 home_shots_off_goal_lag_4
,t2.lag_total_shots_1 home_total_shots_lag_1
,t2.lag_total_shots_2 home_total_shots_lag_2
,t2.lag_total_shots_3 home_total_shots_lag_3
,t2.lag_total_shots_4 home_total_shots_lag_4
,t2.lag_blocked_shots_1 home_blocked_shots_lag_1
,t2.lag_blocked_shots_2 home_blocked_shots_lag_2
,t2.lag_blocked_shots_3 home_blocked_shots_lag_3
,t2.lag_blocked_shots_4 home_blocked_shots_lag_4
,t2.lag_shots_insidebox_1 home_shots_insidebox_lag_1
,t2.lag_shots_insidebox_2 home_shots_insidebox_lag_2
,t2.lag_shots_insidebox_3 home_shots_insidebox_lag_3
,t2.lag_shots_insidebox_4 home_shots_insidebox_lag_4
,t2.lag_shots_outsidebox_1 home_shots_outsidebox_lag_1
,t2.lag_shots_outsidebox_2 home_shots_outsidebox_lag_2
,t2.lag_shots_outsidebox_3 home_shots_outsidebox_lag_3
,t2.lag_shots_outsidebox_4 home_shots_outsidebox_lag_4
,t2.lag_fouls_1 home_fouls_lag_1
,t2.lag_fouls_2 home_fouls_lag_2
,t2.lag_fouls_3 home_fouls_lag_3
,t2.lag_fouls_4 home_fouls_lag_4
,t2.lag_corner_kicks_1 home_corner_kicks_lag_1
,t2.lag_corner_kicks_2 home_corner_kicks_lag_2
,t2.lag_corner_kicks_3 home_corner_kicks_lag_3
,t2.lag_corner_kicks_4 home_corner_kicks_lag_4
,t2.lag_offsides_1 home_offsides_lag_1
,t2.lag_offsides_2 home_offsides_lag_2
,t2.lag_offsides_3 home_offsides_lag_3
,t2.lag_offsides_4 home_offsides_lag_4
,t2.lag_ball_possession_1 home_ball_possession_lag_1
,t2.lag_ball_possession_2 home_ball_possession_lag_2
,t2.lag_ball_possession_3 home_ball_possession_lag_3
,t2.lag_ball_possession_4 home_ball_possession_lag_4
,t2.lag_yellow_cards_1 home_yellow_cards_lag_1
,t2.lag_yellow_cards_2 home_yellow_cards_lag_2
,t2.lag_yellow_cards_3 home_yellow_cards_lag_3
,t2.lag_yellow_cards_4 home_yellow_cards_lag_4
,t2.lag_red_cards_1 home_red_cards_lag_1
,t2.lag_red_cards_2 home_red_cards_lag_2
,t2.lag_red_cards_3 home_red_cards_lag_3
,t2.lag_red_cards_4 home_red_cards_lag_4
,t2.lag_goalkeeper_saves_1 home_goalkeeper_saves_lag_1
,t2.lag_goalkeeper_saves_2 home_goalkeeper_saves_lag_2
,t2.lag_goalkeeper_saves_3 home_goalkeeper_saves_lag_3
,t2.lag_goalkeeper_saves_4 home_goalkeeper_saves_lag_4
,t2.lag_total_passes_1 home_total_passes_lag_1
,t2.lag_total_passes_2 home_total_passes_lag_2
,t2.lag_total_passes_3 home_total_passes_lag_3
,t2.lag_total_passes_4 home_total_passes_lag_4
,t2.lag_passes_accurate_1 home_passes_accurate_lag_1
,t2.lag_passes_accurate_2 home_passes_accurate_lag_2
,t2.lag_passes_accurate_3 home_passes_accurate_lag_3
,t2.lag_passes_accurate_4 home_passes_accurate_lag_4
,t2.lag_passes_perc_1 home_passes_perc_lag_1
,t2.lag_passes_perc_2 home_passes_perc_lag_2
,t2.lag_passes_perc_3 home_passes_perc_lag_3
,t2.lag_passes_perc_4 home_passes_perc_lag_4
,t2.lag_goals_prevented_1 home_goals_prevented_lag_1
,t2.lag_goals_prevented_2 home_goals_prevented_lag_2
,t2.lag_goals_prevented_3 home_goals_prevented_lag_3
,t2.lag_goals_prevented_4 home_goals_prevented_lag_4
,t2.lag_card_reviewed_1 home_card_reviewed_lag_1
,t2.lag_card_reviewed_2 home_card_reviewed_lag_2
,t2.lag_card_reviewed_3 home_card_reviewed_lag_3
,t2.lag_card_reviewed_4 home_card_reviewed_lag_4
,t2.lag_card_upgrade_1 home_card_upgrade_lag_1
,t2.lag_card_upgrade_2 home_card_upgrade_lag_2
,t2.lag_card_upgrade_3 home_card_upgrade_lag_3
,t2.lag_card_upgrade_4 home_card_upgrade_lag_4
,t2.lag_goal_cancelled_1 home_goal_cancelled_lag_1
,t2.lag_goal_cancelled_2 home_goal_cancelled_lag_2
,t2.lag_goal_cancelled_3 home_goal_cancelled_lag_3
,t2.lag_goal_cancelled_4 home_goal_cancelled_lag_4
,t2.lag_goal_confirmed_1 home_goal_confirmed_lag_1
,t2.lag_goal_confirmed_2 home_goal_confirmed_lag_2
,t2.lag_goal_confirmed_3 home_goal_confirmed_lag_3
,t2.lag_goal_confirmed_4 home_goal_confirmed_lag_4
,t2.lag_goal_disallowed_1 home_goal_disallowed_lag_1
,t2.lag_goal_disallowed_2 home_goal_disallowed_lag_2
,t2.lag_goal_disallowed_3 home_goal_disallowed_lag_3
,t2.lag_goal_disallowed_4 home_goal_disallowed_lag_4
,t2.lag_goal_disallowed_foul_1 home_goal_disallowed_foul_lag_1
,t2.lag_goal_disallowed_foul_2 home_goal_disallowed_foul_lag_2
,t2.lag_goal_disallowed_foul_3 home_goal_disallowed_foul_lag_3
,t2.lag_goal_disallowed_foul_4 home_goal_disallowed_foul_lag_4
,t2.lag_goal_disallowed_handball_1 home_goal_disallowed_handball_lag_1
,t2.lag_goal_disallowed_handball_2 home_goal_disallowed_handball_lag_2
,t2.lag_goal_disallowed_handball_3 home_goal_disallowed_handball_lag_3
,t2.lag_goal_disallowed_handball_4 home_goal_disallowed_handball_lag_4
,t2.lag_goal_disallowed_offside_1 home_goal_disallowed_offside_lag_1
,t2.lag_goal_disallowed_offside_2 home_goal_disallowed_offside_lag_2
,t2.lag_goal_disallowed_offside_3 home_goal_disallowed_offside_lag_3
,t2.lag_goal_disallowed_offside_4 home_goal_disallowed_offside_lag_4
,t2.lag_missed_penalty_1 home_missed_penalty_lag_1
,t2.lag_missed_penalty_2 home_missed_penalty_lag_2
,t2.lag_missed_penalty_3 home_missed_penalty_lag_3
,t2.lag_missed_penalty_4 home_missed_penalty_lag_4
,t2.lag_normal_goal_1 home_normal_goal_lag_1
,t2.lag_normal_goal_2 home_normal_goal_lag_2
,t2.lag_normal_goal_3 home_normal_goal_lag_3
,t2.lag_normal_goal_4 home_normal_goal_lag_4
,t2.lag_own_goal_1 home_own_goal_lag_1
,t2.lag_own_goal_2 home_own_goal_lag_2
,t2.lag_own_goal_3 home_own_goal_lag_3
,t2.lag_own_goal_4 home_own_goal_lag_4
,t2.lag_penalty_1 home_penalty_lag_1
,t2.lag_penalty_2 home_penalty_lag_2
,t2.lag_penalty_3 home_penalty_lag_3
,t2.lag_penalty_4 home_penalty_lag_4
,t2.lag_penalty_awarded_1 home_penalty_awarded_lag_1
,t2.lag_penalty_awarded_2 home_penalty_awarded_lag_2
,t2.lag_penalty_awarded_3 home_penalty_awarded_lag_3
,t2.lag_penalty_awarded_4 home_penalty_awarded_lag_4
,t2.lag_penalty_cancelled_1 home_penalty_cancelled_lag_1
,t2.lag_penalty_cancelled_2 home_penalty_cancelled_lag_2
,t2.lag_penalty_cancelled_3 home_penalty_cancelled_lag_3
,t2.lag_penalty_cancelled_4 home_penalty_cancelled_lag_4
,t2.lag_penalty_confirmed_1 home_penalty_confirmed_lag_1
,t2.lag_penalty_confirmed_2 home_penalty_confirmed_lag_2
,t2.lag_penalty_confirmed_3 home_penalty_confirmed_lag_3
,t2.lag_penalty_confirmed_4 home_penalty_confirmed_lag_4
,t2.lag_red_card_1 home_red_card_lag_1
,t2.lag_red_card_2 home_red_card_lag_2
,t2.lag_red_card_3 home_red_card_lag_3
,t2.lag_red_card_4 home_red_card_lag_4
,t2.lag_red_card_cancelled_1 home_red_card_cancelled_lag_1
,t2.lag_red_card_cancelled_2 home_red_card_cancelled_lag_2
,t2.lag_red_card_cancelled_3 home_red_card_cancelled_lag_3
,t2.lag_red_card_cancelled_4 home_red_card_cancelled_lag_4
,t2.lag_substitution_1_1 home_substitution_1_lag_1
,t2.lag_substitution_1_2 home_substitution_1_lag_2
,t2.lag_substitution_1_3 home_substitution_1_lag_3
,t2.lag_substitution_1_4 home_substitution_1_lag_4
,t2.lag_substitution_10_1 home_substitution_10_lag_1
,t2.lag_substitution_10_2 home_substitution_10_lag_2
,t2.lag_substitution_10_3 home_substitution_10_lag_3
,t2.lag_substitution_10_4 home_substitution_10_lag_4
,t2.lag_substitution_11_1 home_substitution_11_lag_1
,t2.lag_substitution_11_2 home_substitution_11_lag_2
,t2.lag_substitution_11_3 home_substitution_11_lag_3
,t2.lag_substitution_11_4 home_substitution_11_lag_4
,t2.lag_substitution_12_1 home_substitution_12_lag_1
,t2.lag_substitution_12_2 home_substitution_12_lag_2
,t2.lag_substitution_12_3 home_substitution_12_lag_3
,t2.lag_substitution_12_4 home_substitution_12_lag_4
,t2.lag_substitution_13_1 home_substitution_13_lag_1
,t2.lag_substitution_13_2 home_substitution_13_lag_2
,t2.lag_substitution_13_3 home_substitution_13_lag_3
,t2.lag_substitution_13_4 home_substitution_13_lag_4
,t2.lag_substitution_14_1 home_substitution_14_lag_1
,t2.lag_substitution_14_2 home_substitution_14_lag_2
,t2.lag_substitution_14_3 home_substitution_14_lag_3
,t2.lag_substitution_14_4 home_substitution_14_lag_4
,t2.lag_substitution_15_1 home_substitution_15_lag_1
,t2.lag_substitution_15_2 home_substitution_15_lag_2
,t2.lag_substitution_15_3 home_substitution_15_lag_3
,t2.lag_substitution_15_4 home_substitution_15_lag_4
,t2.lag_substitution_16_1 home_substitution_16_lag_1
,t2.lag_substitution_16_2 home_substitution_16_lag_2
,t2.lag_substitution_16_3 home_substitution_16_lag_3
,t2.lag_substitution_16_4 home_substitution_16_lag_4
,t2.lag_substitution_17_1 home_substitution_17_lag_1
,t2.lag_substitution_17_2 home_substitution_17_lag_2
,t2.lag_substitution_17_3 home_substitution_17_lag_3
,t2.lag_substitution_17_4 home_substitution_17_lag_4
,t2.lag_substitution_18_1 home_substitution_18_lag_1
,t2.lag_substitution_18_2 home_substitution_18_lag_2
,t2.lag_substitution_18_3 home_substitution_18_lag_3
,t2.lag_substitution_18_4 home_substitution_18_lag_4
,t2.lag_substitution_2_1 home_substitution_2_lag_1
,t2.lag_substitution_2_2 home_substitution_2_lag_2
,t2.lag_substitution_2_3 home_substitution_2_lag_3
,t2.lag_substitution_2_4 home_substitution_2_lag_4
,t2.lag_substitution_3_1 home_substitution_3_lag_1
,t2.lag_substitution_3_2 home_substitution_3_lag_2
,t2.lag_substitution_3_3 home_substitution_3_lag_3
,t2.lag_substitution_3_4 home_substitution_3_lag_4
,t2.lag_substitution_4_1 home_substitution_4_lag_1
,t2.lag_substitution_4_2 home_substitution_4_lag_2
,t2.lag_substitution_4_3 home_substitution_4_lag_3
,t2.lag_substitution_4_4 home_substitution_4_lag_4
,t2.lag_substitution_5_1 home_substitution_5_lag_1
,t2.lag_substitution_5_2 home_substitution_5_lag_2
,t2.lag_substitution_5_3 home_substitution_5_lag_3
,t2.lag_substitution_5_4 home_substitution_5_lag_4
,t2.lag_substitution_6_1 home_substitution_6_lag_1
,t2.lag_substitution_6_2 home_substitution_6_lag_2
,t2.lag_substitution_6_3 home_substitution_6_lag_3
,t2.lag_substitution_6_4 home_substitution_6_lag_4
,t2.lag_substitution_7_1 home_substitution_7_lag_1
,t2.lag_substitution_7_2 home_substitution_7_lag_2
,t2.lag_substitution_7_3 home_substitution_7_lag_3
,t2.lag_substitution_7_4 home_substitution_7_lag_4
,t2.lag_substitution_8_1 home_substitution_8_lag_1
,t2.lag_substitution_8_2 home_substitution_8_lag_2
,t2.lag_substitution_8_3 home_substitution_8_lag_3
,t2.lag_substitution_8_4 home_substitution_8_lag_4
,t2.lag_substitution_9_1 home_substitution_9_lag_1
,t2.lag_substitution_9_2 home_substitution_9_lag_2
,t2.lag_substitution_9_3 home_substitution_9_lag_3
,t2.lag_substitution_9_4 home_substitution_9_lag_4
,t2.lag_yellow_card_1 home_yellow_card_lag_1
,t2.lag_yellow_card_2 home_yellow_card_lag_2
,t2.lag_yellow_card_3 home_yellow_card_lag_3
,t2.lag_yellow_card_4 home_yellow_card_lag_4
,t2.lag_games_minutes_1 home_games_minutes_lag_1
,t2.lag_games_minutes_2 home_games_minutes_lag_2
,t2.lag_games_minutes_3 home_games_minutes_lag_3
,t2.lag_games_minutes_4 home_games_minutes_lag_4
,t2.lag_shots_total_1 home_shots_total_lag_1
,t2.lag_shots_total_2 home_shots_total_lag_2
,t2.lag_shots_total_3 home_shots_total_lag_3
,t2.lag_shots_total_4 home_shots_total_lag_4
,t2.lag_shots_on_1 home_shots_on_lag_1
,t2.lag_shots_on_2 home_shots_on_lag_2
,t2.lag_shots_on_3 home_shots_on_lag_3
,t2.lag_shots_on_4 home_shots_on_lag_4
,t2.lag_goals_total_1 home_goals_total_lag_1
,t2.lag_goals_total_2 home_goals_total_lag_2
,t2.lag_goals_total_3 home_goals_total_lag_3
,t2.lag_goals_total_4 home_goals_total_lag_4
,t2.lag_goals_conceded_1 home_goals_conceded_lag_1
,t2.lag_goals_conceded_2 home_goals_conceded_lag_2
,t2.lag_goals_conceded_3 home_goals_conceded_lag_3
,t2.lag_goals_conceded_4 home_goals_conceded_lag_4
,t2.lag_goals_assists_1 home_goals_assists_lag_1
,t2.lag_goals_assists_2 home_goals_assists_lag_2
,t2.lag_goals_assists_3 home_goals_assists_lag_3
,t2.lag_goals_assists_4 home_goals_assists_lag_4
,t2.lag_goals_saves_1 home_goals_saves_lag_1
,t2.lag_goals_saves_2 home_goals_saves_lag_2
,t2.lag_goals_saves_3 home_goals_saves_lag_3
,t2.lag_goals_saves_4 home_goals_saves_lag_4
,t2.lag_passes_total_1 home_passes_total_lag_1
,t2.lag_passes_total_2 home_passes_total_lag_2
,t2.lag_passes_total_3 home_passes_total_lag_3
,t2.lag_passes_total_4 home_passes_total_lag_4
,t2.lag_passes_key_1 home_passes_key_lag_1
,t2.lag_passes_key_2 home_passes_key_lag_2
,t2.lag_passes_key_3 home_passes_key_lag_3
,t2.lag_passes_key_4 home_passes_key_lag_4
,t2.lag_passes_accuracy_1 home_passes_accuracy_lag_1
,t2.lag_passes_accuracy_2 home_passes_accuracy_lag_2
,t2.lag_passes_accuracy_3 home_passes_accuracy_lag_3
,t2.lag_passes_accuracy_4 home_passes_accuracy_lag_4
,t2.lag_tackles_total_1 home_tackles_total_lag_1
,t2.lag_tackles_total_2 home_tackles_total_lag_2
,t2.lag_tackles_total_3 home_tackles_total_lag_3
,t2.lag_tackles_total_4 home_tackles_total_lag_4
,t2.lag_tackles_blocks_1 home_tackles_blocks_lag_1
,t2.lag_tackles_blocks_2 home_tackles_blocks_lag_2
,t2.lag_tackles_blocks_3 home_tackles_blocks_lag_3
,t2.lag_tackles_blocks_4 home_tackles_blocks_lag_4
,t2.lag_tackles_interceptions_1 home_tackles_interceptions_lag_1
,t2.lag_tackles_interceptions_2 home_tackles_interceptions_lag_2
,t2.lag_tackles_interceptions_3 home_tackles_interceptions_lag_3
,t2.lag_tackles_interceptions_4 home_tackles_interceptions_lag_4
,t2.lag_duels_total_1 home_duels_total_lag_1
,t2.lag_duels_total_2 home_duels_total_lag_2
,t2.lag_duels_total_3 home_duels_total_lag_3
,t2.lag_duels_total_4 home_duels_total_lag_4
,t2.lag_duels_won_1 home_duels_won_lag_1
,t2.lag_duels_won_2 home_duels_won_lag_2
,t2.lag_duels_won_3 home_duels_won_lag_3
,t2.lag_duels_won_4 home_duels_won_lag_4
,t2.lag_dribbles_attempts_1 home_dribbles_attempts_lag_1
,t2.lag_dribbles_attempts_2 home_dribbles_attempts_lag_2
,t2.lag_dribbles_attempts_3 home_dribbles_attempts_lag_3
,t2.lag_dribbles_attempts_4 home_dribbles_attempts_lag_4
,t2.lag_dribbles_success_1 home_dribbles_success_lag_1
,t2.lag_dribbles_success_2 home_dribbles_success_lag_2
,t2.lag_dribbles_success_3 home_dribbles_success_lag_3
,t2.lag_dribbles_success_4 home_dribbles_success_lag_4
,t2.lag_dribbles_past_1 home_dribbles_past_lag_1
,t2.lag_dribbles_past_2 home_dribbles_past_lag_2
,t2.lag_dribbles_past_3 home_dribbles_past_lag_3
,t2.lag_dribbles_past_4 home_dribbles_past_lag_4
,t2.lag_fouls_drawn_1 home_fouls_drawn_lag_1
,t2.lag_fouls_drawn_2 home_fouls_drawn_lag_2
,t2.lag_fouls_drawn_3 home_fouls_drawn_lag_3
,t2.lag_fouls_drawn_4 home_fouls_drawn_lag_4
,t2.lag_fouls_committed_1 home_fouls_committed_lag_1
,t2.lag_fouls_committed_2 home_fouls_committed_lag_2
,t2.lag_fouls_committed_3 home_fouls_committed_lag_3
,t2.lag_fouls_committed_4 home_fouls_committed_lag_4
,t2.lag_cards_yellow_1 home_cards_yellow_lag_1
,t2.lag_cards_yellow_2 home_cards_yellow_lag_2
,t2.lag_cards_yellow_3 home_cards_yellow_lag_3
,t2.lag_cards_yellow_4 home_cards_yellow_lag_4
,t2.lag_cards_red_1 home_cards_red_lag_1
,t2.lag_cards_red_2 home_cards_red_lag_2
,t2.lag_cards_red_3 home_cards_red_lag_3
,t2.lag_cards_red_4 home_cards_red_lag_4
,t2.lag_penalty_won_1 home_penalty_won_lag_1
,t2.lag_penalty_won_2 home_penalty_won_lag_2
,t2.lag_penalty_won_3 home_penalty_won_lag_3
,t2.lag_penalty_won_4 home_penalty_won_lag_4
,t2.lag_penalty_commited_1 home_penalty_commited_lag_1
,t2.lag_penalty_commited_2 home_penalty_commited_lag_2
,t2.lag_penalty_commited_3 home_penalty_commited_lag_3
,t2.lag_penalty_commited_4 home_penalty_commited_lag_4
,t2.lag_penalty_scored_1 home_penalty_scored_lag_1
,t2.lag_penalty_scored_2 home_penalty_scored_lag_2
,t2.lag_penalty_scored_3 home_penalty_scored_lag_3
,t2.lag_penalty_scored_4 home_penalty_scored_lag_4
,t2.lag_penalty_missed_1 home_penalty_missed_lag_1
,t2.lag_penalty_missed_2 home_penalty_missed_lag_2
,t2.lag_penalty_missed_3 home_penalty_missed_lag_3
,t2.lag_penalty_missed_4 home_penalty_missed_lag_4
,t2.lag_penalty_saved_1 home_penalty_saved_lag_1
,t2.lag_penalty_saved_2 home_penalty_saved_lag_2
,t2.lag_penalty_saved_3 home_penalty_saved_lag_3
,t2.lag_penalty_saved_4 home_penalty_saved_lag_4
,t2.shots_on_goal_slope_3 home_shots_on_goal_slope_last_3
,t2.shots_off_goal_slope_3 home_shots_off_goal_slope_last_3
,t2.total_shots_slope_3 home_total_shots_slope_last_3
,t2.blocked_shots_slope_3 home_blocked_shots_slope_last_3
,t2.shots_insidebox_slope_3 home_shots_insidebox_slope_last_3
,t2.shots_outsidebox_slope_3 home_shots_outsidebox_slope_last_3
,t2.fouls_slope_3 home_fouls_slope_last_3
,t2.corner_kicks_slope_3 home_corner_kicks_slope_last_3
,t2.offsides_slope_3 home_offsides_slope_last_3
,t2.ball_possession_slope_3 home_ball_possession_slope_last_3
,t2.yellow_cards_slope_3 home_yellow_cards_slope_last_3
,t2.red_cards_slope_3 home_red_cards_slope_last_3
,t2.goalkeeper_saves_slope_3 home_goalkeeper_saves_slope_last_3
,t2.total_passes_slope_3 home_total_passes_slope_last_3
,t2.passes_accurate_slope_3 home_passes_accurate_slope_last_3
,t2.passes_perc_slope_3 home_passes_perc_slope_last_3
,t2.goals_prevented_slope_3 home_goals_prevented_slope_last_3
,t2.card_reviewed_slope_3 home_card_reviewed_slope_last_3
,t2.card_upgrade_slope_3 home_card_upgrade_slope_last_3
,t2.goal_cancelled_slope_3 home_goal_cancelled_slope_last_3
,t2.goal_confirmed_slope_3 home_goal_confirmed_slope_last_3
,t2.goal_disallowed_slope_3 home_goal_disallowed_slope_last_3
,t2.goal_disallowed_foul_slope_3 home_goal_disallowed_foul_slope_last_3
,t2.goal_disallowed_handball_slope_3 home_goal_disallowed_handball_slope_last_3
,t2.goal_disallowed_offside_slope_3 home_goal_disallowed_offside_slope_last_3
,t2.missed_penalty_slope_3 home_missed_penalty_slope_last_3
,t2.normal_goal_slope_3 home_normal_goal_slope_last_3
,t2.own_goal_slope_3 home_own_goal_slope_last_3
,t2.penalty_slope_3 home_penalty_slope_last_3
,t2.penalty_awarded_slope_3 home_penalty_awarded_slope_last_3
,t2.penalty_cancelled_slope_3 home_penalty_cancelled_slope_last_3
,t2.penalty_confirmed_slope_3 home_penalty_confirmed_slope_last_3
,t2.red_card_slope_3 home_red_card_slope_last_3
,t2.red_card_cancelled_slope_3 home_red_card_cancelled_slope_last_3
,t2.substitution_1_slope_3 home_substitution_1_slope_last_3
,t2.substitution_10_slope_3 home_substitution_10_slope_last_3
,t2.substitution_11_slope_3 home_substitution_11_slope_last_3
,t2.substitution_12_slope_3 home_substitution_12_slope_last_3
,t2.substitution_13_slope_3 home_substitution_13_slope_last_3
,t2.substitution_14_slope_3 home_substitution_14_slope_last_3
,t2.substitution_15_slope_3 home_substitution_15_slope_last_3
,t2.substitution_16_slope_3 home_substitution_16_slope_last_3
,t2.substitution_17_slope_3 home_substitution_17_slope_last_3
,t2.substitution_18_slope_3 home_substitution_18_slope_last_3
,t2.substitution_2_slope_3 home_substitution_2_slope_last_3
,t2.substitution_3_slope_3 home_substitution_3_slope_last_3
,t2.substitution_4_slope_3 home_substitution_4_slope_last_3
,t2.substitution_5_slope_3 home_substitution_5_slope_last_3
,t2.substitution_6_slope_3 home_substitution_6_slope_last_3
,t2.substitution_7_slope_3 home_substitution_7_slope_last_3
,t2.substitution_8_slope_3 home_substitution_8_slope_last_3
,t2.substitution_9_slope_3 home_substitution_9_slope_last_3
,t2.yellow_card_slope_3 home_yellow_card_slope_last_3
,t2.games_minutes_slope_3 home_games_minutes_slope_last_3
,t2.shots_total_slope_3 home_shots_total_slope_last_3
,t2.shots_on_slope_3 home_shots_on_slope_last_3
,t2.goals_total_slope_3 home_goals_total_slope_last_3
,t2.goals_conceded_slope_3 home_goals_conceded_slope_last_3
,t2.goals_assists_slope_3 home_goals_assists_slope_last_3
,t2.goals_saves_slope_3 home_goals_saves_slope_last_3
,t2.passes_total_slope_3 home_passes_total_slope_last_3
,t2.passes_key_slope_3 home_passes_key_slope_last_3
,t2.passes_accuracy_slope_3 home_passes_accuracy_slope_last_3
,t2.tackles_total_slope_3 home_tackles_total_slope_last_3
,t2.tackles_blocks_slope_3 home_tackles_blocks_slope_last_3
,t2.tackles_interceptions_slope_3 home_tackles_interceptions_slope_last_3
,t2.duels_total_slope_3 home_duels_total_slope_last_3
,t2.duels_won_slope_3 home_duels_won_slope_last_3
,t2.dribbles_attempts_slope_3 home_dribbles_attempts_slope_last_3
,t2.dribbles_success_slope_3 home_dribbles_success_slope_last_3
,t2.dribbles_past_slope_3 home_dribbles_past_slope_last_3
,t2.fouls_drawn_slope_3 home_fouls_drawn_slope_last_3
,t2.fouls_committed_slope_3 home_fouls_committed_slope_last_3
,t2.cards_yellow_slope_3 home_cards_yellow_slope_last_3
,t2.cards_red_slope_3 home_cards_red_slope_last_3
,t2.penalty_won_slope_3 home_penalty_won_slope_last_3
,t2.penalty_commited_slope_3 home_penalty_commited_slope_last_3
,t2.penalty_scored_slope_3 home_penalty_scored_slope_last_3
,t2.penalty_missed_slope_3 home_penalty_missed_slope_last_3
,t2.penalty_saved_slope_3 home_penalty_saved_slope_last_3
,t2.goals_slope_t3 home_goals_slope_tlast_3
,t2.sum_shots_on_goal_3 home_shots_on_goal_sum_last_3
,t2.sum_shots_off_goal_3 home_shots_off_goal_sum_last_3
,t2.sum_total_shots_3 home_total_shots_sum_last_3
,t2.sum_blocked_shots_3 home_blocked_shots_sum_last_3
,t2.sum_shots_insidebox_3 home_shots_insidebox_sum_last_3
,t2.sum_shots_outsidebox_3 home_shots_outsidebox_sum_last_3
,t2.sum_fouls_3 home_fouls_sum_last_3
,t2.sum_corner_kicks_3 home_corner_kicks_sum_last_3
,t2.sum_offsides_3 home_offsides_sum_last_3
,t2.sum_ball_possession_3 home_ball_possession_sum_last_3
,t2.sum_yellow_cards_3 home_yellow_cards_sum_last_3
,t2.sum_red_cards_3 home_red_cards_sum_last_3
,t2.sum_goalkeeper_saves_3 home_goalkeeper_saves_sum_last_3
,t2.sum_total_passes_3 home_total_passes_sum_last_3
,t2.sum_passes_accurate_3 home_passes_accurate_sum_last_3
,t2.sum_passes_perc_3 home_passes_perc_sum_last_3
,t2.sum_goals_prevented_3 home_goals_prevented_sum_last_3
,t2.sum_card_reviewed_3 home_card_reviewed_sum_last_3
,t2.sum_card_upgrade_3 home_card_upgrade_sum_last_3
,t2.sum_goal_cancelled_3 home_goal_cancelled_sum_last_3
,t2.sum_goal_confirmed_3 home_goal_confirmed_sum_last_3
,t2.sum_goal_disallowed_3 home_goal_disallowed_sum_last_3
,t2.sum_goal_disallowed_foul_3 home_goal_disallowed_foul_sum_last_3
,t2.sum_goal_disallowed_handball_3 home_goal_disallowed_handball_sum_last_3
,t2.sum_goal_disallowed_offside_3 home_goal_disallowed_offside_sum_last_3
,t2.sum_missed_penalty_3 home_missed_penalty_sum_last_3
,t2.sum_normal_goal_3 home_normal_goal_sum_last_3
,t2.sum_own_goal_3 home_own_goal_sum_last_3
,t2.sum_penalty_3 home_penalty_sum_last_3
,t2.sum_penalty_awarded_3 home_penalty_awarded_sum_last_3
,t2.sum_penalty_cancelled_3 home_penalty_cancelled_sum_last_3
,t2.sum_penalty_confirmed_3 home_penalty_confirmed_sum_last_3
,t2.sum_red_card_3 home_red_card_sum_last_3
,t2.sum_red_card_cancelled_3 home_red_card_cancelled_sum_last_3
,t2.sum_substitution_1_3 home_substitution_1_sum_last_3
,t2.sum_substitution_10_3 home_substitution_10_sum_last_3
,t2.sum_substitution_11_3 home_substitution_11_sum_last_3
,t2.sum_substitution_12_3 home_substitution_12_sum_last_3
,t2.sum_substitution_13_3 home_substitution_13_sum_last_3
,t2.sum_substitution_14_3 home_substitution_14_sum_last_3
,t2.sum_substitution_15_3 home_substitution_15_sum_last_3
,t2.sum_substitution_16_3 home_substitution_16_sum_last_3
,t2.sum_substitution_17_3 home_substitution_17_sum_last_3
,t2.sum_substitution_18_3 home_substitution_18_sum_last_3
,t2.sum_substitution_2_3 home_substitution_2_sum_last_3
,t2.sum_substitution_3_3 home_substitution_3_sum_last_3
,t2.sum_substitution_4_3 home_substitution_4_sum_last_3
,t2.sum_substitution_5_3 home_substitution_5_sum_last_3
,t2.sum_substitution_6_3 home_substitution_6_sum_last_3
,t2.sum_substitution_7_3 home_substitution_7_sum_last_3
,t2.sum_substitution_8_3 home_substitution_8_sum_last_3
,t2.sum_substitution_9_3 home_substitution_9_sum_last_3
,t2.sum_yellow_card_3 home_yellow_card_sum_last_3
,t2.sum_games_minutes_3 home_games_minutes_sum_last_3
,t2.sum_shots_total_3 home_shots_total_sum_last_3
,t2.sum_shots_on_3 home_shots_on_sum_last_3
,t2.sum_goals_total_3 home_goals_total_sum_last_3
,t2.sum_goals_conceded_3 home_goals_conceded_sum_last_3
,t2.sum_goals_assists_3 home_goals_assists_sum_last_3
,t2.sum_goals_saves_3 home_goals_saves_sum_last_3
,t2.sum_passes_total_3 home_passes_total_sum_last_3
,t2.sum_passes_key_3 home_passes_key_sum_last_3
,t2.sum_passes_accuracy_3 home_passes_accuracy_sum_last_3
,t2.sum_tackles_total_3 home_tackles_total_sum_last_3
,t2.sum_tackles_blocks_3 home_tackles_blocks_sum_last_3
,t2.sum_tackles_interceptions_3 home_tackles_interceptions_sum_last_3
,t2.sum_duels_total_3 home_duels_total_sum_last_3
,t2.sum_duels_won_3 home_duels_won_sum_last_3
,t2.sum_dribbles_attempts_3 home_dribbles_attempts_sum_last_3
,t2.sum_dribbles_success_3 home_dribbles_success_sum_last_3
,t2.sum_dribbles_past_3 home_dribbles_past_sum_last_3
,t2.sum_fouls_drawn_3 home_fouls_drawn_sum_last_3
,t2.sum_fouls_committed_3 home_fouls_committed_sum_last_3
,t2.sum_cards_yellow_3 home_cards_yellow_sum_last_3
,t2.sum_cards_red_3 home_cards_red_sum_last_3
,t2.sum_penalty_won_3 home_penalty_won_sum_last_3
,t2.sum_penalty_commited_3 home_penalty_commited_sum_last_3
,t2.sum_penalty_scored_3 home_penalty_scored_sum_last_3
,t2.sum_penalty_missed_3 home_penalty_missed_sum_last_3
,t2.sum_penalty_saved_3 home_penalty_saved_sum_last_3
,t2.avg_shots_on_goal_3 home_shots_on_goal_avg_last_3
,t2.max_shots_on_goal_3 home_shots_on_goal_max_last_3
,t2.min_shots_on_goal_3 home_shots_on_goal_min_last_3
,t2.avg_shots_off_goal_3 home_shots_off_goal_avg_last_3
,t2.max_shots_off_goal_3 home_shots_off_goal_max_last_3
,t2.min_shots_off_goal_3 home_shots_off_goal_min_last_3
,t2.avg_total_shots_3 home_total_shots_avg_last_3
,t2.max_total_shots_3 home_total_shots_max_last_3
,t2.min_total_shots_3 home_total_shots_min_last_3
,t2.avg_blocked_shots_3 home_blocked_shots_avg_last_3
,t2.max_blocked_shots_3 home_blocked_shots_max_last_3
,t2.min_blocked_shots_3 home_blocked_shots_min_last_3
,t2.avg_shots_insidebox_3 home_shots_insidebox_avg_last_3
,t2.max_shots_insidebox_3 home_shots_insidebox_max_last_3
,t2.min_shots_insidebox_3 home_shots_insidebox_min_last_3
,t2.avg_shots_outsidebox_3 home_shots_outsidebox_avg_last_3
,t2.max_shots_outsidebox_3 home_shots_outsidebox_max_last_3
,t2.min_shots_outsidebox_3 home_shots_outsidebox_min_last_3
,t2.avg_fouls_3 home_fouls_avg_last_3
,t2.max_fouls_3 home_fouls_max_last_3
,t2.min_fouls_3 home_fouls_min_last_3
,t2.avg_corner_kicks_3 home_corner_kicks_avg_last_3
,t2.max_corner_kicks_3 home_corner_kicks_max_last_3
,t2.min_corner_kicks_3 home_corner_kicks_min_last_3
,t2.avg_offsides_3 home_offsides_avg_last_3
,t2.max_offsides_3 home_offsides_max_last_3
,t2.min_offsides_3 home_offsides_min_last_3
,t2.avg_ball_possession_3 home_ball_possession_avg_last_3
,t2.max_ball_possession_3 home_ball_possession_max_last_3
,t2.min_ball_possession_3 home_ball_possession_min_last_3
,t2.avg_yellow_cards_3 home_yellow_cards_avg_last_3
,t2.max_yellow_cards_3 home_yellow_cards_max_last_3
,t2.min_yellow_cards_3 home_yellow_cards_min_last_3
,t2.avg_red_cards_3 home_red_cards_avg_last_3
,t2.max_red_cards_3 home_red_cards_max_last_3
,t2.min_red_cards_3 home_red_cards_min_last_3
,t2.avg_goalkeeper_saves_3 home_goalkeeper_saves_avg_last_3
,t2.max_goalkeeper_saves_3 home_goalkeeper_saves_max_last_3
,t2.min_goalkeeper_saves_3 home_goalkeeper_saves_min_last_3
,t2.avg_total_passes_3 home_total_passes_avg_last_3
,t2.max_total_passes_3 home_total_passes_max_last_3
,t2.min_total_passes_3 home_total_passes_min_last_3
,t2.avg_passes_accurate_3 home_passes_accurate_avg_last_3
,t2.max_passes_accurate_3 home_passes_accurate_max_last_3
,t2.min_passes_accurate_3 home_passes_accurate_min_last_3
,t2.avg_passes_perc_3 home_passes_perc_avg_last_3
,t2.max_passes_perc_3 home_passes_perc_max_last_3
,t2.min_passes_perc_3 home_passes_perc_min_last_3
,t2.avg_goals_prevented_3 home_goals_prevented_avg_last_3
,t2.max_goals_prevented_3 home_goals_prevented_max_last_3
,t2.min_goals_prevented_3 home_goals_prevented_min_last_3
,t2.avg_card_reviewed_3 home_card_reviewed_avg_last_3
,t2.max_card_reviewed_3 home_card_reviewed_max_last_3
,t2.min_card_reviewed_3 home_card_reviewed_min_last_3
,t2.avg_card_upgrade_3 home_card_upgrade_avg_last_3
,t2.max_card_upgrade_3 home_card_upgrade_max_last_3
,t2.min_card_upgrade_3 home_card_upgrade_min_last_3
,t2.avg_goal_cancelled_3 home_goal_cancelled_avg_last_3
,t2.max_goal_cancelled_3 home_goal_cancelled_max_last_3
,t2.min_goal_cancelled_3 home_goal_cancelled_min_last_3
,t2.avg_goal_confirmed_3 home_goal_confirmed_avg_last_3
,t2.max_goal_confirmed_3 home_goal_confirmed_max_last_3
,t2.min_goal_confirmed_3 home_goal_confirmed_min_last_3
,t2.avg_goal_disallowed_3 home_goal_disallowed_avg_last_3
,t2.max_goal_disallowed_3 home_goal_disallowed_max_last_3
,t2.min_goal_disallowed_3 home_goal_disallowed_min_last_3
,t2.avg_goal_disallowed_foul_3 home_goal_disallowed_foul_avg_last_3
,t2.max_goal_disallowed_foul_3 home_goal_disallowed_foul_max_last_3
,t2.min_goal_disallowed_foul_3 home_goal_disallowed_foul_min_last_3
,t2.avg_goal_disallowed_handball_3 home_goal_disallowed_handball_avg_last_3
,t2.max_goal_disallowed_handball_3 home_goal_disallowed_handball_max_last_3
,t2.min_goal_disallowed_handball_3 home_goal_disallowed_handball_min_last_3
,t2.avg_goal_disallowed_offside_3 home_goal_disallowed_offside_avg_last_3
,t2.max_goal_disallowed_offside_3 home_goal_disallowed_offside_max_last_3
,t2.min_goal_disallowed_offside_3 home_goal_disallowed_offside_min_last_3
,t2.avg_missed_penalty_3 home_missed_penalty_avg_last_3
,t2.max_missed_penalty_3 home_missed_penalty_max_last_3
,t2.min_missed_penalty_3 home_missed_penalty_min_last_3
,t2.avg_normal_goal_3 home_normal_goal_avg_last_3
,t2.max_normal_goal_3 home_normal_goal_max_last_3
,t2.min_normal_goal_3 home_normal_goal_min_last_3
,t2.avg_own_goal_3 home_own_goal_avg_last_3
,t2.max_own_goal_3 home_own_goal_max_last_3
,t2.min_own_goal_3 home_own_goal_min_last_3
,t2.avg_penalty_3 home_penalty_avg_last_3
,t2.max_penalty_3 home_penalty_max_last_3
,t2.min_penalty_3 home_penalty_min_last_3
,t2.avg_penalty_awarded_3 home_penalty_awarded_avg_last_3
,t2.max_penalty_awarded_3 home_penalty_awarded_max_last_3
,t2.min_penalty_awarded_3 home_penalty_awarded_min_last_3
,t2.avg_penalty_cancelled_3 home_penalty_cancelled_avg_last_3
,t2.max_penalty_cancelled_3 home_penalty_cancelled_max_last_3
,t2.min_penalty_cancelled_3 home_penalty_cancelled_min_last_3
,t2.avg_penalty_confirmed_3 home_penalty_confirmed_avg_last_3
,t2.max_penalty_confirmed_3 home_penalty_confirmed_max_last_3
,t2.min_penalty_confirmed_3 home_penalty_confirmed_min_last_3
,t2.avg_red_card_3 home_red_card_avg_last_3
,t2.max_red_card_3 home_red_card_max_last_3
,t2.min_red_card_3 home_red_card_min_last_3
,t2.avg_red_card_cancelled_3 home_red_card_cancelled_avg_last_3
,t2.max_red_card_cancelled_3 home_red_card_cancelled_max_last_3
,t2.min_red_card_cancelled_3 home_red_card_cancelled_min_last_3
,t2.avg_substitution_1_3 home_substitution_1_avg_last_3
,t2.max_substitution_1_3 home_substitution_1_max_last_3
,t2.min_substitution_1_3 home_substitution_1_min_last_3
,t2.avg_substitution_10_3 home_substitution_10_avg_last_3
,t2.max_substitution_10_3 home_substitution_10_max_last_3
,t2.min_substitution_10_3 home_substitution_10_min_last_3
,t2.avg_substitution_11_3 home_substitution_11_avg_last_3
,t2.max_substitution_11_3 home_substitution_11_max_last_3
,t2.min_substitution_11_3 home_substitution_11_min_last_3
,t2.avg_substitution_12_3 home_substitution_12_avg_last_3
,t2.max_substitution_12_3 home_substitution_12_max_last_3
,t2.min_substitution_12_3 home_substitution_12_min_last_3
,t2.avg_substitution_13_3 home_substitution_13_avg_last_3
,t2.max_substitution_13_3 home_substitution_13_max_last_3
,t2.min_substitution_13_3 home_substitution_13_min_last_3
,t2.avg_substitution_14_3 home_substitution_14_avg_last_3
,t2.max_substitution_14_3 home_substitution_14_max_last_3
,t2.min_substitution_14_3 home_substitution_14_min_last_3
,t2.avg_substitution_15_3 home_substitution_15_avg_last_3
,t2.max_substitution_15_3 home_substitution_15_max_last_3
,t2.min_substitution_15_3 home_substitution_15_min_last_3
,t2.avg_substitution_16_3 home_substitution_16_avg_last_3
,t2.max_substitution_16_3 home_substitution_16_max_last_3
,t2.min_substitution_16_3 home_substitution_16_min_last_3
,t2.avg_substitution_17_3 home_substitution_17_avg_last_3
,t2.max_substitution_17_3 home_substitution_17_max_last_3
,t2.min_substitution_17_3 home_substitution_17_min_last_3
,t2.avg_substitution_18_3 home_substitution_18_avg_last_3
,t2.max_substitution_18_3 home_substitution_18_max_last_3
,t2.min_substitution_18_3 home_substitution_18_min_last_3
,t2.avg_substitution_2_3 home_substitution_2_avg_last_3
,t2.max_substitution_2_3 home_substitution_2_max_last_3
,t2.min_substitution_2_3 home_substitution_2_min_last_3
,t2.avg_substitution_3_3 home_substitution_3_avg_last_3
,t2.max_substitution_3_3 home_substitution_3_max_last_3
,t2.min_substitution_3_3 home_substitution_3_min_last_3
,t2.avg_substitution_4_3 home_substitution_4_avg_last_3
,t2.max_substitution_4_3 home_substitution_4_max_last_3
,t2.min_substitution_4_3 home_substitution_4_min_last_3
,t2.avg_substitution_5_3 home_substitution_5_avg_last_3
,t2.max_substitution_5_3 home_substitution_5_max_last_3
,t2.min_substitution_5_3 home_substitution_5_min_last_3
,t2.avg_substitution_6_3 home_substitution_6_avg_last_3
,t2.max_substitution_6_3 home_substitution_6_max_last_3
,t2.min_substitution_6_3 home_substitution_6_min_last_3
,t2.avg_substitution_7_3 home_substitution_7_avg_last_3
,t2.max_substitution_7_3 home_substitution_7_max_last_3
,t2.min_substitution_7_3 home_substitution_7_min_last_3
,t2.avg_substitution_8_3 home_substitution_8_avg_last_3
,t2.max_substitution_8_3 home_substitution_8_max_last_3
,t2.min_substitution_8_3 home_substitution_8_min_last_3
,t2.avg_substitution_9_3 home_substitution_9_avg_last_3
,t2.max_substitution_9_3 home_substitution_9_max_last_3
,t2.min_substitution_9_3 home_substitution_9_min_last_3
,t2.avg_yellow_card_3 home_yellow_card_avg_last_3
,t2.max_yellow_card_3 home_yellow_card_max_last_3
,t2.min_yellow_card_3 home_yellow_card_min_last_3
,t2.avg_games_minutes_3 home_games_minutes_avg_last_3
,t2.max_games_minutes_3 home_games_minutes_max_last_3
,t2.min_games_minutes_3 home_games_minutes_min_last_3
,t2.avg_shots_total_3 home_shots_total_avg_last_3
,t2.max_shots_total_3 home_shots_total_max_last_3
,t2.min_shots_total_3 home_shots_total_min_last_3
,t2.avg_shots_on_3 home_shots_on_avg_last_3
,t2.max_shots_on_3 home_shots_on_max_last_3
,t2.min_shots_on_3 home_shots_on_min_last_3
,t2.avg_goals_total_3 home_goals_total_avg_last_3
,t2.max_goals_total_3 home_goals_total_max_last_3
,t2.min_goals_total_3 home_goals_total_min_last_3
,t2.avg_goals_conceded_3 home_goals_conceded_avg_last_3
,t2.max_goals_conceded_3 home_goals_conceded_max_last_3
,t2.min_goals_conceded_3 home_goals_conceded_min_last_3
,t2.avg_goals_assists_3 home_goals_assists_avg_last_3
,t2.max_goals_assists_3 home_goals_assists_max_last_3
,t2.min_goals_assists_3 home_goals_assists_min_last_3
,t2.avg_goals_saves_3 home_goals_saves_avg_last_3
,t2.max_goals_saves_3 home_goals_saves_max_last_3
,t2.min_goals_saves_3 home_goals_saves_min_last_3
,t2.avg_passes_total_3 home_passes_total_avg_last_3
,t2.max_passes_total_3 home_passes_total_max_last_3
,t2.min_passes_total_3 home_passes_total_min_last_3
,t2.avg_passes_key_3 home_passes_key_avg_last_3
,t2.max_passes_key_3 home_passes_key_max_last_3
,t2.min_passes_key_3 home_passes_key_min_last_3
,t2.avg_passes_accuracy_3 home_passes_accuracy_avg_last_3
,t2.max_passes_accuracy_3 home_passes_accuracy_max_last_3
,t2.min_passes_accuracy_3 home_passes_accuracy_min_last_3
,t2.avg_tackles_total_3 home_tackles_total_avg_last_3
,t2.max_tackles_total_3 home_tackles_total_max_last_3
,t2.min_tackles_total_3 home_tackles_total_min_last_3
,t2.avg_tackles_blocks_3 home_tackles_blocks_avg_last_3
,t2.max_tackles_blocks_3 home_tackles_blocks_max_last_3
,t2.min_tackles_blocks_3 home_tackles_blocks_min_last_3
,t2.avg_tackles_interceptions_3 home_tackles_interceptions_avg_last_3
,t2.max_tackles_interceptions_3 home_tackles_interceptions_max_last_3
,t2.min_tackles_interceptions_3 home_tackles_interceptions_min_last_3
,t2.avg_duels_total_3 home_duels_total_avg_last_3
,t2.max_duels_total_3 home_duels_total_max_last_3
,t2.min_duels_total_3 home_duels_total_min_last_3
,t2.avg_duels_won_3 home_duels_won_avg_last_3
,t2.max_duels_won_3 home_duels_won_max_last_3
,t2.min_duels_won_3 home_duels_won_min_last_3
,t2.avg_dribbles_attempts_3 home_dribbles_attempts_avg_last_3
,t2.max_dribbles_attempts_3 home_dribbles_attempts_max_last_3
,t2.min_dribbles_attempts_3 home_dribbles_attempts_min_last_3
,t2.avg_dribbles_success_3 home_dribbles_success_avg_last_3
,t2.max_dribbles_success_3 home_dribbles_success_max_last_3
,t2.min_dribbles_success_3 home_dribbles_success_min_last_3
,t2.avg_dribbles_past_3 home_dribbles_past_avg_last_3
,t2.max_dribbles_past_3 home_dribbles_past_max_last_3
,t2.min_dribbles_past_3 home_dribbles_past_min_last_3
,t2.avg_fouls_drawn_3 home_fouls_drawn_avg_last_3
,t2.max_fouls_drawn_3 home_fouls_drawn_max_last_3
,t2.min_fouls_drawn_3 home_fouls_drawn_min_last_3
,t2.avg_fouls_committed_3 home_fouls_committed_avg_last_3
,t2.max_fouls_committed_3 home_fouls_committed_max_last_3
,t2.min_fouls_committed_3 home_fouls_committed_min_last_3
,t2.avg_cards_yellow_3 home_cards_yellow_avg_last_3
,t2.max_cards_yellow_3 home_cards_yellow_max_last_3
,t2.min_cards_yellow_3 home_cards_yellow_min_last_3
,t2.avg_cards_red_3 home_cards_red_avg_last_3
,t2.max_cards_red_3 home_cards_red_max_last_3
,t2.min_cards_red_3 home_cards_red_min_last_3
,t2.avg_penalty_won_3 home_penalty_won_avg_last_3
,t2.max_penalty_won_3 home_penalty_won_max_last_3
,t2.min_penalty_won_3 home_penalty_won_min_last_3
,t2.avg_penalty_commited_3 home_penalty_commited_avg_last_3
,t2.max_penalty_commited_3 home_penalty_commited_max_last_3
,t2.min_penalty_commited_3 home_penalty_commited_min_last_3
,t2.avg_penalty_scored_3 home_penalty_scored_avg_last_3
,t2.max_penalty_scored_3 home_penalty_scored_max_last_3
,t2.min_penalty_scored_3 home_penalty_scored_min_last_3
,t2.avg_penalty_missed_3 home_penalty_missed_avg_last_3
,t2.max_penalty_missed_3 home_penalty_missed_max_last_3
,t2.min_penalty_missed_3 home_penalty_missed_min_last_3
,t2.avg_penalty_saved_3 home_penalty_saved_avg_last_3
,t2.max_penalty_saved_3 home_penalty_saved_max_last_3
,t2.min_penalty_saved_3 home_penalty_saved_min_last_3

,t3.lag_goals_1 away_goals_lag_1
,t3.lag_goals_2 away_goals_lag_2
,t3.lag_goals_3 away_goals_lag_3
,t3.lag_goals_4 away_goals_lag_4
,t3.lag_is_winner_1 away_is_winner_lag_1
,t3.lag_is_winner_2 away_is_winner_lag_2
,t3.lag_is_winner_3 away_is_winner_lag_3
,t3.lag_is_winner_4 away_is_winner_lag_4
,t3.lag_is_home_1 away_is_home_lag_1
,t3.lag_is_home_2 away_is_home_lag_2
,t3.lag_is_home_3 away_is_home_lag_3
,t3.lag_is_home_4 away_is_home_lag_4
,t3.lag_shots_on_goal_1 away_shots_on_goal_lag_1
,t3.lag_shots_on_goal_2 away_shots_on_goal_lag_2
,t3.lag_shots_on_goal_3 away_shots_on_goal_lag_3
,t3.lag_shots_on_goal_4 away_shots_on_goal_lag_4
,t3.lag_shots_off_goal_1 away_shots_off_goal_lag_1
,t3.lag_shots_off_goal_2 away_shots_off_goal_lag_2
,t3.lag_shots_off_goal_3 away_shots_off_goal_lag_3
,t3.lag_shots_off_goal_4 away_shots_off_goal_lag_4
,t3.lag_total_shots_1 away_total_shots_lag_1
,t3.lag_total_shots_2 away_total_shots_lag_2
,t3.lag_total_shots_3 away_total_shots_lag_3
,t3.lag_total_shots_4 away_total_shots_lag_4
,t3.lag_blocked_shots_1 away_blocked_shots_lag_1
,t3.lag_blocked_shots_2 away_blocked_shots_lag_2
,t3.lag_blocked_shots_3 away_blocked_shots_lag_3
,t3.lag_blocked_shots_4 away_blocked_shots_lag_4
,t3.lag_shots_insidebox_1 away_shots_insidebox_lag_1
,t3.lag_shots_insidebox_2 away_shots_insidebox_lag_2
,t3.lag_shots_insidebox_3 away_shots_insidebox_lag_3
,t3.lag_shots_insidebox_4 away_shots_insidebox_lag_4
,t3.lag_shots_outsidebox_1 away_shots_outsidebox_lag_1
,t3.lag_shots_outsidebox_2 away_shots_outsidebox_lag_2
,t3.lag_shots_outsidebox_3 away_shots_outsidebox_lag_3
,t3.lag_shots_outsidebox_4 away_shots_outsidebox_lag_4
,t3.lag_fouls_1 away_fouls_lag_1
,t3.lag_fouls_2 away_fouls_lag_2
,t3.lag_fouls_3 away_fouls_lag_3
,t3.lag_fouls_4 away_fouls_lag_4
,t3.lag_corner_kicks_1 away_corner_kicks_lag_1
,t3.lag_corner_kicks_2 away_corner_kicks_lag_2
,t3.lag_corner_kicks_3 away_corner_kicks_lag_3
,t3.lag_corner_kicks_4 away_corner_kicks_lag_4
,t3.lag_offsides_1 away_offsides_lag_1
,t3.lag_offsides_2 away_offsides_lag_2
,t3.lag_offsides_3 away_offsides_lag_3
,t3.lag_offsides_4 away_offsides_lag_4
,t3.lag_ball_possession_1 away_ball_possession_lag_1
,t3.lag_ball_possession_2 away_ball_possession_lag_2
,t3.lag_ball_possession_3 away_ball_possession_lag_3
,t3.lag_ball_possession_4 away_ball_possession_lag_4
,t3.lag_yellow_cards_1 away_yellow_cards_lag_1
,t3.lag_yellow_cards_2 away_yellow_cards_lag_2
,t3.lag_yellow_cards_3 away_yellow_cards_lag_3
,t3.lag_yellow_cards_4 away_yellow_cards_lag_4
,t3.lag_red_cards_1 away_red_cards_lag_1
,t3.lag_red_cards_2 away_red_cards_lag_2
,t3.lag_red_cards_3 away_red_cards_lag_3
,t3.lag_red_cards_4 away_red_cards_lag_4
,t3.lag_goalkeeper_saves_1 away_goalkeeper_saves_lag_1
,t3.lag_goalkeeper_saves_2 away_goalkeeper_saves_lag_2
,t3.lag_goalkeeper_saves_3 away_goalkeeper_saves_lag_3
,t3.lag_goalkeeper_saves_4 away_goalkeeper_saves_lag_4
,t3.lag_total_passes_1 away_total_passes_lag_1
,t3.lag_total_passes_2 away_total_passes_lag_2
,t3.lag_total_passes_3 away_total_passes_lag_3
,t3.lag_total_passes_4 away_total_passes_lag_4
,t3.lag_passes_accurate_1 away_passes_accurate_lag_1
,t3.lag_passes_accurate_2 away_passes_accurate_lag_2
,t3.lag_passes_accurate_3 away_passes_accurate_lag_3
,t3.lag_passes_accurate_4 away_passes_accurate_lag_4
,t3.lag_passes_perc_1 away_passes_perc_lag_1
,t3.lag_passes_perc_2 away_passes_perc_lag_2
,t3.lag_passes_perc_3 away_passes_perc_lag_3
,t3.lag_passes_perc_4 away_passes_perc_lag_4
,t3.lag_goals_prevented_1 away_goals_prevented_lag_1
,t3.lag_goals_prevented_2 away_goals_prevented_lag_2
,t3.lag_goals_prevented_3 away_goals_prevented_lag_3
,t3.lag_goals_prevented_4 away_goals_prevented_lag_4
,t3.lag_card_reviewed_1 away_card_reviewed_lag_1
,t3.lag_card_reviewed_2 away_card_reviewed_lag_2
,t3.lag_card_reviewed_3 away_card_reviewed_lag_3
,t3.lag_card_reviewed_4 away_card_reviewed_lag_4
,t3.lag_card_upgrade_1 away_card_upgrade_lag_1
,t3.lag_card_upgrade_2 away_card_upgrade_lag_2
,t3.lag_card_upgrade_3 away_card_upgrade_lag_3
,t3.lag_card_upgrade_4 away_card_upgrade_lag_4
,t3.lag_goal_cancelled_1 away_goal_cancelled_lag_1
,t3.lag_goal_cancelled_2 away_goal_cancelled_lag_2
,t3.lag_goal_cancelled_3 away_goal_cancelled_lag_3
,t3.lag_goal_cancelled_4 away_goal_cancelled_lag_4
,t3.lag_goal_confirmed_1 away_goal_confirmed_lag_1
,t3.lag_goal_confirmed_2 away_goal_confirmed_lag_2
,t3.lag_goal_confirmed_3 away_goal_confirmed_lag_3
,t3.lag_goal_confirmed_4 away_goal_confirmed_lag_4
,t3.lag_goal_disallowed_1 away_goal_disallowed_lag_1
,t3.lag_goal_disallowed_2 away_goal_disallowed_lag_2
,t3.lag_goal_disallowed_3 away_goal_disallowed_lag_3
,t3.lag_goal_disallowed_4 away_goal_disallowed_lag_4
,t3.lag_goal_disallowed_foul_1 away_goal_disallowed_foul_lag_1
,t3.lag_goal_disallowed_foul_2 away_goal_disallowed_foul_lag_2
,t3.lag_goal_disallowed_foul_3 away_goal_disallowed_foul_lag_3
,t3.lag_goal_disallowed_foul_4 away_goal_disallowed_foul_lag_4
,t3.lag_goal_disallowed_handball_1 away_goal_disallowed_handball_lag_1
,t3.lag_goal_disallowed_handball_2 away_goal_disallowed_handball_lag_2
,t3.lag_goal_disallowed_handball_3 away_goal_disallowed_handball_lag_3
,t3.lag_goal_disallowed_handball_4 away_goal_disallowed_handball_lag_4
,t3.lag_goal_disallowed_offside_1 away_goal_disallowed_offside_lag_1
,t3.lag_goal_disallowed_offside_2 away_goal_disallowed_offside_lag_2
,t3.lag_goal_disallowed_offside_3 away_goal_disallowed_offside_lag_3
,t3.lag_goal_disallowed_offside_4 away_goal_disallowed_offside_lag_4
,t3.lag_missed_penalty_1 away_missed_penalty_lag_1
,t3.lag_missed_penalty_2 away_missed_penalty_lag_2
,t3.lag_missed_penalty_3 away_missed_penalty_lag_3
,t3.lag_missed_penalty_4 away_missed_penalty_lag_4
,t3.lag_normal_goal_1 away_normal_goal_lag_1
,t3.lag_normal_goal_2 away_normal_goal_lag_2
,t3.lag_normal_goal_3 away_normal_goal_lag_3
,t3.lag_normal_goal_4 away_normal_goal_lag_4
,t3.lag_own_goal_1 away_own_goal_lag_1
,t3.lag_own_goal_2 away_own_goal_lag_2
,t3.lag_own_goal_3 away_own_goal_lag_3
,t3.lag_own_goal_4 away_own_goal_lag_4
,t3.lag_penalty_1 away_penalty_lag_1
,t3.lag_penalty_2 away_penalty_lag_2
,t3.lag_penalty_3 away_penalty_lag_3
,t3.lag_penalty_4 away_penalty_lag_4
,t3.lag_penalty_awarded_1 away_penalty_awarded_lag_1
,t3.lag_penalty_awarded_2 away_penalty_awarded_lag_2
,t3.lag_penalty_awarded_3 away_penalty_awarded_lag_3
,t3.lag_penalty_awarded_4 away_penalty_awarded_lag_4
,t3.lag_penalty_cancelled_1 away_penalty_cancelled_lag_1
,t3.lag_penalty_cancelled_2 away_penalty_cancelled_lag_2
,t3.lag_penalty_cancelled_3 away_penalty_cancelled_lag_3
,t3.lag_penalty_cancelled_4 away_penalty_cancelled_lag_4
,t3.lag_penalty_confirmed_1 away_penalty_confirmed_lag_1
,t3.lag_penalty_confirmed_2 away_penalty_confirmed_lag_2
,t3.lag_penalty_confirmed_3 away_penalty_confirmed_lag_3
,t3.lag_penalty_confirmed_4 away_penalty_confirmed_lag_4
,t3.lag_red_card_1 away_red_card_lag_1
,t3.lag_red_card_2 away_red_card_lag_2
,t3.lag_red_card_3 away_red_card_lag_3
,t3.lag_red_card_4 away_red_card_lag_4
,t3.lag_red_card_cancelled_1 away_red_card_cancelled_lag_1
,t3.lag_red_card_cancelled_2 away_red_card_cancelled_lag_2
,t3.lag_red_card_cancelled_3 away_red_card_cancelled_lag_3
,t3.lag_red_card_cancelled_4 away_red_card_cancelled_lag_4
,t3.lag_substitution_1_1 away_substitution_1_lag_1
,t3.lag_substitution_1_2 away_substitution_1_lag_2
,t3.lag_substitution_1_3 away_substitution_1_lag_3
,t3.lag_substitution_1_4 away_substitution_1_lag_4
,t3.lag_substitution_10_1 away_substitution_10_lag_1
,t3.lag_substitution_10_2 away_substitution_10_lag_2
,t3.lag_substitution_10_3 away_substitution_10_lag_3
,t3.lag_substitution_10_4 away_substitution_10_lag_4
,t3.lag_substitution_11_1 away_substitution_11_lag_1
,t3.lag_substitution_11_2 away_substitution_11_lag_2
,t3.lag_substitution_11_3 away_substitution_11_lag_3
,t3.lag_substitution_11_4 away_substitution_11_lag_4
,t3.lag_substitution_12_1 away_substitution_12_lag_1
,t3.lag_substitution_12_2 away_substitution_12_lag_2
,t3.lag_substitution_12_3 away_substitution_12_lag_3
,t3.lag_substitution_12_4 away_substitution_12_lag_4
,t3.lag_substitution_13_1 away_substitution_13_lag_1
,t3.lag_substitution_13_2 away_substitution_13_lag_2
,t3.lag_substitution_13_3 away_substitution_13_lag_3
,t3.lag_substitution_13_4 away_substitution_13_lag_4
,t3.lag_substitution_14_1 away_substitution_14_lag_1
,t3.lag_substitution_14_2 away_substitution_14_lag_2
,t3.lag_substitution_14_3 away_substitution_14_lag_3
,t3.lag_substitution_14_4 away_substitution_14_lag_4
,t3.lag_substitution_15_1 away_substitution_15_lag_1
,t3.lag_substitution_15_2 away_substitution_15_lag_2
,t3.lag_substitution_15_3 away_substitution_15_lag_3
,t3.lag_substitution_15_4 away_substitution_15_lag_4
,t3.lag_substitution_16_1 away_substitution_16_lag_1
,t3.lag_substitution_16_2 away_substitution_16_lag_2
,t3.lag_substitution_16_3 away_substitution_16_lag_3
,t3.lag_substitution_16_4 away_substitution_16_lag_4
,t3.lag_substitution_17_1 away_substitution_17_lag_1
,t3.lag_substitution_17_2 away_substitution_17_lag_2
,t3.lag_substitution_17_3 away_substitution_17_lag_3
,t3.lag_substitution_17_4 away_substitution_17_lag_4
,t3.lag_substitution_18_1 away_substitution_18_lag_1
,t3.lag_substitution_18_2 away_substitution_18_lag_2
,t3.lag_substitution_18_3 away_substitution_18_lag_3
,t3.lag_substitution_18_4 away_substitution_18_lag_4
,t3.lag_substitution_2_1 away_substitution_2_lag_1
,t3.lag_substitution_2_2 away_substitution_2_lag_2
,t3.lag_substitution_2_3 away_substitution_2_lag_3
,t3.lag_substitution_2_4 away_substitution_2_lag_4
,t3.lag_substitution_3_1 away_substitution_3_lag_1
,t3.lag_substitution_3_2 away_substitution_3_lag_2
,t3.lag_substitution_3_3 away_substitution_3_lag_3
,t3.lag_substitution_3_4 away_substitution_3_lag_4
,t3.lag_substitution_4_1 away_substitution_4_lag_1
,t3.lag_substitution_4_2 away_substitution_4_lag_2
,t3.lag_substitution_4_3 away_substitution_4_lag_3
,t3.lag_substitution_4_4 away_substitution_4_lag_4
,t3.lag_substitution_5_1 away_substitution_5_lag_1
,t3.lag_substitution_5_2 away_substitution_5_lag_2
,t3.lag_substitution_5_3 away_substitution_5_lag_3
,t3.lag_substitution_5_4 away_substitution_5_lag_4
,t3.lag_substitution_6_1 away_substitution_6_lag_1
,t3.lag_substitution_6_2 away_substitution_6_lag_2
,t3.lag_substitution_6_3 away_substitution_6_lag_3
,t3.lag_substitution_6_4 away_substitution_6_lag_4
,t3.lag_substitution_7_1 away_substitution_7_lag_1
,t3.lag_substitution_7_2 away_substitution_7_lag_2
,t3.lag_substitution_7_3 away_substitution_7_lag_3
,t3.lag_substitution_7_4 away_substitution_7_lag_4
,t3.lag_substitution_8_1 away_substitution_8_lag_1
,t3.lag_substitution_8_2 away_substitution_8_lag_2
,t3.lag_substitution_8_3 away_substitution_8_lag_3
,t3.lag_substitution_8_4 away_substitution_8_lag_4
,t3.lag_substitution_9_1 away_substitution_9_lag_1
,t3.lag_substitution_9_2 away_substitution_9_lag_2
,t3.lag_substitution_9_3 away_substitution_9_lag_3
,t3.lag_substitution_9_4 away_substitution_9_lag_4
,t3.lag_yellow_card_1 away_yellow_card_lag_1
,t3.lag_yellow_card_2 away_yellow_card_lag_2
,t3.lag_yellow_card_3 away_yellow_card_lag_3
,t3.lag_yellow_card_4 away_yellow_card_lag_4
,t3.lag_games_minutes_1 away_games_minutes_lag_1
,t3.lag_games_minutes_2 away_games_minutes_lag_2
,t3.lag_games_minutes_3 away_games_minutes_lag_3
,t3.lag_games_minutes_4 away_games_minutes_lag_4
,t3.lag_shots_total_1 away_shots_total_lag_1
,t3.lag_shots_total_2 away_shots_total_lag_2
,t3.lag_shots_total_3 away_shots_total_lag_3
,t3.lag_shots_total_4 away_shots_total_lag_4
,t3.lag_shots_on_1 away_shots_on_lag_1
,t3.lag_shots_on_2 away_shots_on_lag_2
,t3.lag_shots_on_3 away_shots_on_lag_3
,t3.lag_shots_on_4 away_shots_on_lag_4
,t3.lag_goals_total_1 away_goals_total_lag_1
,t3.lag_goals_total_2 away_goals_total_lag_2
,t3.lag_goals_total_3 away_goals_total_lag_3
,t3.lag_goals_total_4 away_goals_total_lag_4
,t3.lag_goals_conceded_1 away_goals_conceded_lag_1
,t3.lag_goals_conceded_2 away_goals_conceded_lag_2
,t3.lag_goals_conceded_3 away_goals_conceded_lag_3
,t3.lag_goals_conceded_4 away_goals_conceded_lag_4
,t3.lag_goals_assists_1 away_goals_assists_lag_1
,t3.lag_goals_assists_2 away_goals_assists_lag_2
,t3.lag_goals_assists_3 away_goals_assists_lag_3
,t3.lag_goals_assists_4 away_goals_assists_lag_4
,t3.lag_goals_saves_1 away_goals_saves_lag_1
,t3.lag_goals_saves_2 away_goals_saves_lag_2
,t3.lag_goals_saves_3 away_goals_saves_lag_3
,t3.lag_goals_saves_4 away_goals_saves_lag_4
,t3.lag_passes_total_1 away_passes_total_lag_1
,t3.lag_passes_total_2 away_passes_total_lag_2
,t3.lag_passes_total_3 away_passes_total_lag_3
,t3.lag_passes_total_4 away_passes_total_lag_4
,t3.lag_passes_key_1 away_passes_key_lag_1
,t3.lag_passes_key_2 away_passes_key_lag_2
,t3.lag_passes_key_3 away_passes_key_lag_3
,t3.lag_passes_key_4 away_passes_key_lag_4
,t3.lag_passes_accuracy_1 away_passes_accuracy_lag_1
,t3.lag_passes_accuracy_2 away_passes_accuracy_lag_2
,t3.lag_passes_accuracy_3 away_passes_accuracy_lag_3
,t3.lag_passes_accuracy_4 away_passes_accuracy_lag_4
,t3.lag_tackles_total_1 away_tackles_total_lag_1
,t3.lag_tackles_total_2 away_tackles_total_lag_2
,t3.lag_tackles_total_3 away_tackles_total_lag_3
,t3.lag_tackles_total_4 away_tackles_total_lag_4
,t3.lag_tackles_blocks_1 away_tackles_blocks_lag_1
,t3.lag_tackles_blocks_2 away_tackles_blocks_lag_2
,t3.lag_tackles_blocks_3 away_tackles_blocks_lag_3
,t3.lag_tackles_blocks_4 away_tackles_blocks_lag_4
,t3.lag_tackles_interceptions_1 away_tackles_interceptions_lag_1
,t3.lag_tackles_interceptions_2 away_tackles_interceptions_lag_2
,t3.lag_tackles_interceptions_3 away_tackles_interceptions_lag_3
,t3.lag_tackles_interceptions_4 away_tackles_interceptions_lag_4
,t3.lag_duels_total_1 away_duels_total_lag_1
,t3.lag_duels_total_2 away_duels_total_lag_2
,t3.lag_duels_total_3 away_duels_total_lag_3
,t3.lag_duels_total_4 away_duels_total_lag_4
,t3.lag_duels_won_1 away_duels_won_lag_1
,t3.lag_duels_won_2 away_duels_won_lag_2
,t3.lag_duels_won_3 away_duels_won_lag_3
,t3.lag_duels_won_4 away_duels_won_lag_4
,t3.lag_dribbles_attempts_1 away_dribbles_attempts_lag_1
,t3.lag_dribbles_attempts_2 away_dribbles_attempts_lag_2
,t3.lag_dribbles_attempts_3 away_dribbles_attempts_lag_3
,t3.lag_dribbles_attempts_4 away_dribbles_attempts_lag_4
,t3.lag_dribbles_success_1 away_dribbles_success_lag_1
,t3.lag_dribbles_success_2 away_dribbles_success_lag_2
,t3.lag_dribbles_success_3 away_dribbles_success_lag_3
,t3.lag_dribbles_success_4 away_dribbles_success_lag_4
,t3.lag_dribbles_past_1 away_dribbles_past_lag_1
,t3.lag_dribbles_past_2 away_dribbles_past_lag_2
,t3.lag_dribbles_past_3 away_dribbles_past_lag_3
,t3.lag_dribbles_past_4 away_dribbles_past_lag_4
,t3.lag_fouls_drawn_1 away_fouls_drawn_lag_1
,t3.lag_fouls_drawn_2 away_fouls_drawn_lag_2
,t3.lag_fouls_drawn_3 away_fouls_drawn_lag_3
,t3.lag_fouls_drawn_4 away_fouls_drawn_lag_4
,t3.lag_fouls_committed_1 away_fouls_committed_lag_1
,t3.lag_fouls_committed_2 away_fouls_committed_lag_2
,t3.lag_fouls_committed_3 away_fouls_committed_lag_3
,t3.lag_fouls_committed_4 away_fouls_committed_lag_4
,t3.lag_cards_yellow_1 away_cards_yellow_lag_1
,t3.lag_cards_yellow_2 away_cards_yellow_lag_2
,t3.lag_cards_yellow_3 away_cards_yellow_lag_3
,t3.lag_cards_yellow_4 away_cards_yellow_lag_4
,t3.lag_cards_red_1 away_cards_red_lag_1
,t3.lag_cards_red_2 away_cards_red_lag_2
,t3.lag_cards_red_3 away_cards_red_lag_3
,t3.lag_cards_red_4 away_cards_red_lag_4
,t3.lag_penalty_won_1 away_penalty_won_lag_1
,t3.lag_penalty_won_2 away_penalty_won_lag_2
,t3.lag_penalty_won_3 away_penalty_won_lag_3
,t3.lag_penalty_won_4 away_penalty_won_lag_4
,t3.lag_penalty_commited_1 away_penalty_commited_lag_1
,t3.lag_penalty_commited_2 away_penalty_commited_lag_2
,t3.lag_penalty_commited_3 away_penalty_commited_lag_3
,t3.lag_penalty_commited_4 away_penalty_commited_lag_4
,t3.lag_penalty_scored_1 away_penalty_scored_lag_1
,t3.lag_penalty_scored_2 away_penalty_scored_lag_2
,t3.lag_penalty_scored_3 away_penalty_scored_lag_3
,t3.lag_penalty_scored_4 away_penalty_scored_lag_4
,t3.lag_penalty_missed_1 away_penalty_missed_lag_1
,t3.lag_penalty_missed_2 away_penalty_missed_lag_2
,t3.lag_penalty_missed_3 away_penalty_missed_lag_3
,t3.lag_penalty_missed_4 away_penalty_missed_lag_4
,t3.lag_penalty_saved_1 away_penalty_saved_lag_1
,t3.lag_penalty_saved_2 away_penalty_saved_lag_2
,t3.lag_penalty_saved_3 away_penalty_saved_lag_3
,t3.lag_penalty_saved_4 away_penalty_saved_lag_4
,t3.shots_on_goal_slope_3 away_shots_on_goal_slope_last_3
,t3.shots_off_goal_slope_3 away_shots_off_goal_slope_last_3
,t3.total_shots_slope_3 away_total_shots_slope_last_3
,t3.blocked_shots_slope_3 away_blocked_shots_slope_last_3
,t3.shots_insidebox_slope_3 away_shots_insidebox_slope_last_3
,t3.shots_outsidebox_slope_3 away_shots_outsidebox_slope_last_3
,t3.fouls_slope_3 away_fouls_slope_last_3
,t3.corner_kicks_slope_3 away_corner_kicks_slope_last_3
,t3.offsides_slope_3 away_offsides_slope_last_3
,t3.ball_possession_slope_3 away_ball_possession_slope_last_3
,t3.yellow_cards_slope_3 away_yellow_cards_slope_last_3
,t3.red_cards_slope_3 away_red_cards_slope_last_3
,t3.goalkeeper_saves_slope_3 away_goalkeeper_saves_slope_last_3
,t3.total_passes_slope_3 away_total_passes_slope_last_3
,t3.passes_accurate_slope_3 away_passes_accurate_slope_last_3
,t3.passes_perc_slope_3 away_passes_perc_slope_last_3
,t3.goals_prevented_slope_3 away_goals_prevented_slope_last_3
,t3.card_reviewed_slope_3 away_card_reviewed_slope_last_3
,t3.card_upgrade_slope_3 away_card_upgrade_slope_last_3
,t3.goal_cancelled_slope_3 away_goal_cancelled_slope_last_3
,t3.goal_confirmed_slope_3 away_goal_confirmed_slope_last_3
,t3.goal_disallowed_slope_3 away_goal_disallowed_slope_last_3
,t3.goal_disallowed_foul_slope_3 away_goal_disallowed_foul_slope_last_3
,t3.goal_disallowed_handball_slope_3 away_goal_disallowed_handball_slope_last_3
,t3.goal_disallowed_offside_slope_3 away_goal_disallowed_offside_slope_last_3
,t3.missed_penalty_slope_3 away_missed_penalty_slope_last_3
,t3.normal_goal_slope_3 away_normal_goal_slope_last_3
,t3.own_goal_slope_3 away_own_goal_slope_last_3
,t3.penalty_slope_3 away_penalty_slope_last_3
,t3.penalty_awarded_slope_3 away_penalty_awarded_slope_last_3
,t3.penalty_cancelled_slope_3 away_penalty_cancelled_slope_last_3
,t3.penalty_confirmed_slope_3 away_penalty_confirmed_slope_last_3
,t3.red_card_slope_3 away_red_card_slope_last_3
,t3.red_card_cancelled_slope_3 away_red_card_cancelled_slope_last_3
,t3.substitution_1_slope_3 away_substitution_1_slope_last_3
,t3.substitution_10_slope_3 away_substitution_10_slope_last_3
,t3.substitution_11_slope_3 away_substitution_11_slope_last_3
,t3.substitution_12_slope_3 away_substitution_12_slope_last_3
,t3.substitution_13_slope_3 away_substitution_13_slope_last_3
,t3.substitution_14_slope_3 away_substitution_14_slope_last_3
,t3.substitution_15_slope_3 away_substitution_15_slope_last_3
,t3.substitution_16_slope_3 away_substitution_16_slope_last_3
,t3.substitution_17_slope_3 away_substitution_17_slope_last_3
,t3.substitution_18_slope_3 away_substitution_18_slope_last_3
,t3.substitution_2_slope_3 away_substitution_2_slope_last_3
,t3.substitution_3_slope_3 away_substitution_3_slope_last_3
,t3.substitution_4_slope_3 away_substitution_4_slope_last_3
,t3.substitution_5_slope_3 away_substitution_5_slope_last_3
,t3.substitution_6_slope_3 away_substitution_6_slope_last_3
,t3.substitution_7_slope_3 away_substitution_7_slope_last_3
,t3.substitution_8_slope_3 away_substitution_8_slope_last_3
,t3.substitution_9_slope_3 away_substitution_9_slope_last_3
,t3.yellow_card_slope_3 away_yellow_card_slope_last_3
,t3.games_minutes_slope_3 away_games_minutes_slope_last_3
,t3.shots_total_slope_3 away_shots_total_slope_last_3
,t3.shots_on_slope_3 away_shots_on_slope_last_3
,t3.goals_total_slope_3 away_goals_total_slope_last_3
,t3.goals_conceded_slope_3 away_goals_conceded_slope_last_3
,t3.goals_assists_slope_3 away_goals_assists_slope_last_3
,t3.goals_saves_slope_3 away_goals_saves_slope_last_3
,t3.passes_total_slope_3 away_passes_total_slope_last_3
,t3.passes_key_slope_3 away_passes_key_slope_last_3
,t3.passes_accuracy_slope_3 away_passes_accuracy_slope_last_3
,t3.tackles_total_slope_3 away_tackles_total_slope_last_3
,t3.tackles_blocks_slope_3 away_tackles_blocks_slope_last_3
,t3.tackles_interceptions_slope_3 away_tackles_interceptions_slope_last_3
,t3.duels_total_slope_3 away_duels_total_slope_last_3
,t3.duels_won_slope_3 away_duels_won_slope_last_3
,t3.dribbles_attempts_slope_3 away_dribbles_attempts_slope_last_3
,t3.dribbles_success_slope_3 away_dribbles_success_slope_last_3
,t3.dribbles_past_slope_3 away_dribbles_past_slope_last_3
,t3.fouls_drawn_slope_3 away_fouls_drawn_slope_last_3
,t3.fouls_committed_slope_3 away_fouls_committed_slope_last_3
,t3.cards_yellow_slope_3 away_cards_yellow_slope_last_3
,t3.cards_red_slope_3 away_cards_red_slope_last_3
,t3.penalty_won_slope_3 away_penalty_won_slope_last_3
,t3.penalty_commited_slope_3 away_penalty_commited_slope_last_3
,t3.penalty_scored_slope_3 away_penalty_scored_slope_last_3
,t3.penalty_missed_slope_3 away_penalty_missed_slope_last_3
,t3.penalty_saved_slope_3 away_penalty_saved_slope_last_3
,t3.goals_slope_t3 away_goals_slope_tlast_3
,t3.sum_shots_on_goal_3 away_shots_on_goal_sum_last_3
,t3.sum_shots_off_goal_3 away_shots_off_goal_sum_last_3
,t3.sum_total_shots_3 away_total_shots_sum_last_3
,t3.sum_blocked_shots_3 away_blocked_shots_sum_last_3
,t3.sum_shots_insidebox_3 away_shots_insidebox_sum_last_3
,t3.sum_shots_outsidebox_3 away_shots_outsidebox_sum_last_3
,t3.sum_fouls_3 away_fouls_sum_last_3
,t3.sum_corner_kicks_3 away_corner_kicks_sum_last_3
,t3.sum_offsides_3 away_offsides_sum_last_3
,t3.sum_ball_possession_3 away_ball_possession_sum_last_3
,t3.sum_yellow_cards_3 away_yellow_cards_sum_last_3
,t3.sum_red_cards_3 away_red_cards_sum_last_3
,t3.sum_goalkeeper_saves_3 away_goalkeeper_saves_sum_last_3
,t3.sum_total_passes_3 away_total_passes_sum_last_3
,t3.sum_passes_accurate_3 away_passes_accurate_sum_last_3
,t3.sum_passes_perc_3 away_passes_perc_sum_last_3
,t3.sum_goals_prevented_3 away_goals_prevented_sum_last_3
,t3.sum_card_reviewed_3 away_card_reviewed_sum_last_3
,t3.sum_card_upgrade_3 away_card_upgrade_sum_last_3
,t3.sum_goal_cancelled_3 away_goal_cancelled_sum_last_3
,t3.sum_goal_confirmed_3 away_goal_confirmed_sum_last_3
,t3.sum_goal_disallowed_3 away_goal_disallowed_sum_last_3
,t3.sum_goal_disallowed_foul_3 away_goal_disallowed_foul_sum_last_3
,t3.sum_goal_disallowed_handball_3 away_goal_disallowed_handball_sum_last_3
,t3.sum_goal_disallowed_offside_3 away_goal_disallowed_offside_sum_last_3
,t3.sum_missed_penalty_3 away_missed_penalty_sum_last_3
,t3.sum_normal_goal_3 away_normal_goal_sum_last_3
,t3.sum_own_goal_3 away_own_goal_sum_last_3
,t3.sum_penalty_3 away_penalty_sum_last_3
,t3.sum_penalty_awarded_3 away_penalty_awarded_sum_last_3
,t3.sum_penalty_cancelled_3 away_penalty_cancelled_sum_last_3
,t3.sum_penalty_confirmed_3 away_penalty_confirmed_sum_last_3
,t3.sum_red_card_3 away_red_card_sum_last_3
,t3.sum_red_card_cancelled_3 away_red_card_cancelled_sum_last_3
,t3.sum_substitution_1_3 away_substitution_1_sum_last_3
,t3.sum_substitution_10_3 away_substitution_10_sum_last_3
,t3.sum_substitution_11_3 away_substitution_11_sum_last_3
,t3.sum_substitution_12_3 away_substitution_12_sum_last_3
,t3.sum_substitution_13_3 away_substitution_13_sum_last_3
,t3.sum_substitution_14_3 away_substitution_14_sum_last_3
,t3.sum_substitution_15_3 away_substitution_15_sum_last_3
,t3.sum_substitution_16_3 away_substitution_16_sum_last_3
,t3.sum_substitution_17_3 away_substitution_17_sum_last_3
,t3.sum_substitution_18_3 away_substitution_18_sum_last_3
,t3.sum_substitution_2_3 away_substitution_2_sum_last_3
,t3.sum_substitution_3_3 away_substitution_3_sum_last_3
,t3.sum_substitution_4_3 away_substitution_4_sum_last_3
,t3.sum_substitution_5_3 away_substitution_5_sum_last_3
,t3.sum_substitution_6_3 away_substitution_6_sum_last_3
,t3.sum_substitution_7_3 away_substitution_7_sum_last_3
,t3.sum_substitution_8_3 away_substitution_8_sum_last_3
,t3.sum_substitution_9_3 away_substitution_9_sum_last_3
,t3.sum_yellow_card_3 away_yellow_card_sum_last_3
,t3.sum_games_minutes_3 away_games_minutes_sum_last_3
,t3.sum_shots_total_3 away_shots_total_sum_last_3
,t3.sum_shots_on_3 away_shots_on_sum_last_3
,t3.sum_goals_total_3 away_goals_total_sum_last_3
,t3.sum_goals_conceded_3 away_goals_conceded_sum_last_3
,t3.sum_goals_assists_3 away_goals_assists_sum_last_3
,t3.sum_goals_saves_3 away_goals_saves_sum_last_3
,t3.sum_passes_total_3 away_passes_total_sum_last_3
,t3.sum_passes_key_3 away_passes_key_sum_last_3
,t3.sum_passes_accuracy_3 away_passes_accuracy_sum_last_3
,t3.sum_tackles_total_3 away_tackles_total_sum_last_3
,t3.sum_tackles_blocks_3 away_tackles_blocks_sum_last_3
,t3.sum_tackles_interceptions_3 away_tackles_interceptions_sum_last_3
,t3.sum_duels_total_3 away_duels_total_sum_last_3
,t3.sum_duels_won_3 away_duels_won_sum_last_3
,t3.sum_dribbles_attempts_3 away_dribbles_attempts_sum_last_3
,t3.sum_dribbles_success_3 away_dribbles_success_sum_last_3
,t3.sum_dribbles_past_3 away_dribbles_past_sum_last_3
,t3.sum_fouls_drawn_3 away_fouls_drawn_sum_last_3
,t3.sum_fouls_committed_3 away_fouls_committed_sum_last_3
,t3.sum_cards_yellow_3 away_cards_yellow_sum_last_3
,t3.sum_cards_red_3 away_cards_red_sum_last_3
,t3.sum_penalty_won_3 away_penalty_won_sum_last_3
,t3.sum_penalty_commited_3 away_penalty_commited_sum_last_3
,t3.sum_penalty_scored_3 away_penalty_scored_sum_last_3
,t3.sum_penalty_missed_3 away_penalty_missed_sum_last_3
,t3.sum_penalty_saved_3 away_penalty_saved_sum_last_3
,t3.avg_shots_on_goal_3 away_shots_on_goal_avg_last_3
,t3.max_shots_on_goal_3 away_shots_on_goal_max_last_3
,t3.min_shots_on_goal_3 away_shots_on_goal_min_last_3
,t3.avg_shots_off_goal_3 away_shots_off_goal_avg_last_3
,t3.max_shots_off_goal_3 away_shots_off_goal_max_last_3
,t3.min_shots_off_goal_3 away_shots_off_goal_min_last_3
,t3.avg_total_shots_3 away_total_shots_avg_last_3
,t3.max_total_shots_3 away_total_shots_max_last_3
,t3.min_total_shots_3 away_total_shots_min_last_3
,t3.avg_blocked_shots_3 away_blocked_shots_avg_last_3
,t3.max_blocked_shots_3 away_blocked_shots_max_last_3
,t3.min_blocked_shots_3 away_blocked_shots_min_last_3
,t3.avg_shots_insidebox_3 away_shots_insidebox_avg_last_3
,t3.max_shots_insidebox_3 away_shots_insidebox_max_last_3
,t3.min_shots_insidebox_3 away_shots_insidebox_min_last_3
,t3.avg_shots_outsidebox_3 away_shots_outsidebox_avg_last_3
,t3.max_shots_outsidebox_3 away_shots_outsidebox_max_last_3
,t3.min_shots_outsidebox_3 away_shots_outsidebox_min_last_3
,t3.avg_fouls_3 away_fouls_avg_last_3
,t3.max_fouls_3 away_fouls_max_last_3
,t3.min_fouls_3 away_fouls_min_last_3
,t3.avg_corner_kicks_3 away_corner_kicks_avg_last_3
,t3.max_corner_kicks_3 away_corner_kicks_max_last_3
,t3.min_corner_kicks_3 away_corner_kicks_min_last_3
,t3.avg_offsides_3 away_offsides_avg_last_3
,t3.max_offsides_3 away_offsides_max_last_3
,t3.min_offsides_3 away_offsides_min_last_3
,t3.avg_ball_possession_3 away_ball_possession_avg_last_3
,t3.max_ball_possession_3 away_ball_possession_max_last_3
,t3.min_ball_possession_3 away_ball_possession_min_last_3
,t3.avg_yellow_cards_3 away_yellow_cards_avg_last_3
,t3.max_yellow_cards_3 away_yellow_cards_max_last_3
,t3.min_yellow_cards_3 away_yellow_cards_min_last_3
,t3.avg_red_cards_3 away_red_cards_avg_last_3
,t3.max_red_cards_3 away_red_cards_max_last_3
,t3.min_red_cards_3 away_red_cards_min_last_3
,t3.avg_goalkeeper_saves_3 away_goalkeeper_saves_avg_last_3
,t3.max_goalkeeper_saves_3 away_goalkeeper_saves_max_last_3
,t3.min_goalkeeper_saves_3 away_goalkeeper_saves_min_last_3
,t3.avg_total_passes_3 away_total_passes_avg_last_3
,t3.max_total_passes_3 away_total_passes_max_last_3
,t3.min_total_passes_3 away_total_passes_min_last_3
,t3.avg_passes_accurate_3 away_passes_accurate_avg_last_3
,t3.max_passes_accurate_3 away_passes_accurate_max_last_3
,t3.min_passes_accurate_3 away_passes_accurate_min_last_3
,t3.avg_passes_perc_3 away_passes_perc_avg_last_3
,t3.max_passes_perc_3 away_passes_perc_max_last_3
,t3.min_passes_perc_3 away_passes_perc_min_last_3
,t3.avg_goals_prevented_3 away_goals_prevented_avg_last_3
,t3.max_goals_prevented_3 away_goals_prevented_max_last_3
,t3.min_goals_prevented_3 away_goals_prevented_min_last_3
,t3.avg_card_reviewed_3 away_card_reviewed_avg_last_3
,t3.max_card_reviewed_3 away_card_reviewed_max_last_3
,t3.min_card_reviewed_3 away_card_reviewed_min_last_3
,t3.avg_card_upgrade_3 away_card_upgrade_avg_last_3
,t3.max_card_upgrade_3 away_card_upgrade_max_last_3
,t3.min_card_upgrade_3 away_card_upgrade_min_last_3
,t3.avg_goal_cancelled_3 away_goal_cancelled_avg_last_3
,t3.max_goal_cancelled_3 away_goal_cancelled_max_last_3
,t3.min_goal_cancelled_3 away_goal_cancelled_min_last_3
,t3.avg_goal_confirmed_3 away_goal_confirmed_avg_last_3
,t3.max_goal_confirmed_3 away_goal_confirmed_max_last_3
,t3.min_goal_confirmed_3 away_goal_confirmed_min_last_3
,t3.avg_goal_disallowed_3 away_goal_disallowed_avg_last_3
,t3.max_goal_disallowed_3 away_goal_disallowed_max_last_3
,t3.min_goal_disallowed_3 away_goal_disallowed_min_last_3
,t3.avg_goal_disallowed_foul_3 away_goal_disallowed_foul_avg_last_3
,t3.max_goal_disallowed_foul_3 away_goal_disallowed_foul_max_last_3
,t3.min_goal_disallowed_foul_3 away_goal_disallowed_foul_min_last_3
,t3.avg_goal_disallowed_handball_3 away_goal_disallowed_handball_avg_last_3
,t3.max_goal_disallowed_handball_3 away_goal_disallowed_handball_max_last_3
,t3.min_goal_disallowed_handball_3 away_goal_disallowed_handball_min_last_3
,t3.avg_goal_disallowed_offside_3 away_goal_disallowed_offside_avg_last_3
,t3.max_goal_disallowed_offside_3 away_goal_disallowed_offside_max_last_3
,t3.min_goal_disallowed_offside_3 away_goal_disallowed_offside_min_last_3
,t3.avg_missed_penalty_3 away_missed_penalty_avg_last_3
,t3.max_missed_penalty_3 away_missed_penalty_max_last_3
,t3.min_missed_penalty_3 away_missed_penalty_min_last_3
,t3.avg_normal_goal_3 away_normal_goal_avg_last_3
,t3.max_normal_goal_3 away_normal_goal_max_last_3
,t3.min_normal_goal_3 away_normal_goal_min_last_3
,t3.avg_own_goal_3 away_own_goal_avg_last_3
,t3.max_own_goal_3 away_own_goal_max_last_3
,t3.min_own_goal_3 away_own_goal_min_last_3
,t3.avg_penalty_3 away_penalty_avg_last_3
,t3.max_penalty_3 away_penalty_max_last_3
,t3.min_penalty_3 away_penalty_min_last_3
,t3.avg_penalty_awarded_3 away_penalty_awarded_avg_last_3
,t3.max_penalty_awarded_3 away_penalty_awarded_max_last_3
,t3.min_penalty_awarded_3 away_penalty_awarded_min_last_3
,t3.avg_penalty_cancelled_3 away_penalty_cancelled_avg_last_3
,t3.max_penalty_cancelled_3 away_penalty_cancelled_max_last_3
,t3.min_penalty_cancelled_3 away_penalty_cancelled_min_last_3
,t3.avg_penalty_confirmed_3 away_penalty_confirmed_avg_last_3
,t3.max_penalty_confirmed_3 away_penalty_confirmed_max_last_3
,t3.min_penalty_confirmed_3 away_penalty_confirmed_min_last_3
,t3.avg_red_card_3 away_red_card_avg_last_3
,t3.max_red_card_3 away_red_card_max_last_3
,t3.min_red_card_3 away_red_card_min_last_3
,t3.avg_red_card_cancelled_3 away_red_card_cancelled_avg_last_3
,t3.max_red_card_cancelled_3 away_red_card_cancelled_max_last_3
,t3.min_red_card_cancelled_3 away_red_card_cancelled_min_last_3
,t3.avg_substitution_1_3 away_substitution_1_avg_last_3
,t3.max_substitution_1_3 away_substitution_1_max_last_3
,t3.min_substitution_1_3 away_substitution_1_min_last_3
,t3.avg_substitution_10_3 away_substitution_10_avg_last_3
,t3.max_substitution_10_3 away_substitution_10_max_last_3
,t3.min_substitution_10_3 away_substitution_10_min_last_3
,t3.avg_substitution_11_3 away_substitution_11_avg_last_3
,t3.max_substitution_11_3 away_substitution_11_max_last_3
,t3.min_substitution_11_3 away_substitution_11_min_last_3
,t3.avg_substitution_12_3 away_substitution_12_avg_last_3
,t3.max_substitution_12_3 away_substitution_12_max_last_3
,t3.min_substitution_12_3 away_substitution_12_min_last_3
,t3.avg_substitution_13_3 away_substitution_13_avg_last_3
,t3.max_substitution_13_3 away_substitution_13_max_last_3
,t3.min_substitution_13_3 away_substitution_13_min_last_3
,t3.avg_substitution_14_3 away_substitution_14_avg_last_3
,t3.max_substitution_14_3 away_substitution_14_max_last_3
,t3.min_substitution_14_3 away_substitution_14_min_last_3
,t3.avg_substitution_15_3 away_substitution_15_avg_last_3
,t3.max_substitution_15_3 away_substitution_15_max_last_3
,t3.min_substitution_15_3 away_substitution_15_min_last_3
,t3.avg_substitution_16_3 away_substitution_16_avg_last_3
,t3.max_substitution_16_3 away_substitution_16_max_last_3
,t3.min_substitution_16_3 away_substitution_16_min_last_3
,t3.avg_substitution_17_3 away_substitution_17_avg_last_3
,t3.max_substitution_17_3 away_substitution_17_max_last_3
,t3.min_substitution_17_3 away_substitution_17_min_last_3
,t3.avg_substitution_18_3 away_substitution_18_avg_last_3
,t3.max_substitution_18_3 away_substitution_18_max_last_3
,t3.min_substitution_18_3 away_substitution_18_min_last_3
,t3.avg_substitution_2_3 away_substitution_2_avg_last_3
,t3.max_substitution_2_3 away_substitution_2_max_last_3
,t3.min_substitution_2_3 away_substitution_2_min_last_3
,t3.avg_substitution_3_3 away_substitution_3_avg_last_3
,t3.max_substitution_3_3 away_substitution_3_max_last_3
,t3.min_substitution_3_3 away_substitution_3_min_last_3
,t3.avg_substitution_4_3 away_substitution_4_avg_last_3
,t3.max_substitution_4_3 away_substitution_4_max_last_3
,t3.min_substitution_4_3 away_substitution_4_min_last_3
,t3.avg_substitution_5_3 away_substitution_5_avg_last_3
,t3.max_substitution_5_3 away_substitution_5_max_last_3
,t3.min_substitution_5_3 away_substitution_5_min_last_3
,t3.avg_substitution_6_3 away_substitution_6_avg_last_3
,t3.max_substitution_6_3 away_substitution_6_max_last_3
,t3.min_substitution_6_3 away_substitution_6_min_last_3
,t3.avg_substitution_7_3 away_substitution_7_avg_last_3
,t3.max_substitution_7_3 away_substitution_7_max_last_3
,t3.min_substitution_7_3 away_substitution_7_min_last_3
,t3.avg_substitution_8_3 away_substitution_8_avg_last_3
,t3.max_substitution_8_3 away_substitution_8_max_last_3
,t3.min_substitution_8_3 away_substitution_8_min_last_3
,t3.avg_substitution_9_3 away_substitution_9_avg_last_3
,t3.max_substitution_9_3 away_substitution_9_max_last_3
,t3.min_substitution_9_3 away_substitution_9_min_last_3
,t3.avg_yellow_card_3 away_yellow_card_avg_last_3
,t3.max_yellow_card_3 away_yellow_card_max_last_3
,t3.min_yellow_card_3 away_yellow_card_min_last_3
,t3.avg_games_minutes_3 away_games_minutes_avg_last_3
,t3.max_games_minutes_3 away_games_minutes_max_last_3
,t3.min_games_minutes_3 away_games_minutes_min_last_3
,t3.avg_shots_total_3 away_shots_total_avg_last_3
,t3.max_shots_total_3 away_shots_total_max_last_3
,t3.min_shots_total_3 away_shots_total_min_last_3
,t3.avg_shots_on_3 away_shots_on_avg_last_3
,t3.max_shots_on_3 away_shots_on_max_last_3
,t3.min_shots_on_3 away_shots_on_min_last_3
,t3.avg_goals_total_3 away_goals_total_avg_last_3
,t3.max_goals_total_3 away_goals_total_max_last_3
,t3.min_goals_total_3 away_goals_total_min_last_3
,t3.avg_goals_conceded_3 away_goals_conceded_avg_last_3
,t3.max_goals_conceded_3 away_goals_conceded_max_last_3
,t3.min_goals_conceded_3 away_goals_conceded_min_last_3
,t3.avg_goals_assists_3 away_goals_assists_avg_last_3
,t3.max_goals_assists_3 away_goals_assists_max_last_3
,t3.min_goals_assists_3 away_goals_assists_min_last_3
,t3.avg_goals_saves_3 away_goals_saves_avg_last_3
,t3.max_goals_saves_3 away_goals_saves_max_last_3
,t3.min_goals_saves_3 away_goals_saves_min_last_3
,t3.avg_passes_total_3 away_passes_total_avg_last_3
,t3.max_passes_total_3 away_passes_total_max_last_3
,t3.min_passes_total_3 away_passes_total_min_last_3
,t3.avg_passes_key_3 away_passes_key_avg_last_3
,t3.max_passes_key_3 away_passes_key_max_last_3
,t3.min_passes_key_3 away_passes_key_min_last_3
,t3.avg_passes_accuracy_3 away_passes_accuracy_avg_last_3
,t3.max_passes_accuracy_3 away_passes_accuracy_max_last_3
,t3.min_passes_accuracy_3 away_passes_accuracy_min_last_3
,t3.avg_tackles_total_3 away_tackles_total_avg_last_3
,t3.max_tackles_total_3 away_tackles_total_max_last_3
,t3.min_tackles_total_3 away_tackles_total_min_last_3
,t3.avg_tackles_blocks_3 away_tackles_blocks_avg_last_3
,t3.max_tackles_blocks_3 away_tackles_blocks_max_last_3
,t3.min_tackles_blocks_3 away_tackles_blocks_min_last_3
,t3.avg_tackles_interceptions_3 away_tackles_interceptions_avg_last_3
,t3.max_tackles_interceptions_3 away_tackles_interceptions_max_last_3
,t3.min_tackles_interceptions_3 away_tackles_interceptions_min_last_3
,t3.avg_duels_total_3 away_duels_total_avg_last_3
,t3.max_duels_total_3 away_duels_total_max_last_3
,t3.min_duels_total_3 away_duels_total_min_last_3
,t3.avg_duels_won_3 away_duels_won_avg_last_3
,t3.max_duels_won_3 away_duels_won_max_last_3
,t3.min_duels_won_3 away_duels_won_min_last_3
,t3.avg_dribbles_attempts_3 away_dribbles_attempts_avg_last_3
,t3.max_dribbles_attempts_3 away_dribbles_attempts_max_last_3
,t3.min_dribbles_attempts_3 away_dribbles_attempts_min_last_3
,t3.avg_dribbles_success_3 away_dribbles_success_avg_last_3
,t3.max_dribbles_success_3 away_dribbles_success_max_last_3
,t3.min_dribbles_success_3 away_dribbles_success_min_last_3
,t3.avg_dribbles_past_3 away_dribbles_past_avg_last_3
,t3.max_dribbles_past_3 away_dribbles_past_max_last_3
,t3.min_dribbles_past_3 away_dribbles_past_min_last_3
,t3.avg_fouls_drawn_3 away_fouls_drawn_avg_last_3
,t3.max_fouls_drawn_3 away_fouls_drawn_max_last_3
,t3.min_fouls_drawn_3 away_fouls_drawn_min_last_3
,t3.avg_fouls_committed_3 away_fouls_committed_avg_last_3
,t3.max_fouls_committed_3 away_fouls_committed_max_last_3
,t3.min_fouls_committed_3 away_fouls_committed_min_last_3
,t3.avg_cards_yellow_3 away_cards_yellow_avg_last_3
,t3.max_cards_yellow_3 away_cards_yellow_max_last_3
,t3.min_cards_yellow_3 away_cards_yellow_min_last_3
,t3.avg_cards_red_3 away_cards_red_avg_last_3
,t3.max_cards_red_3 away_cards_red_max_last_3
,t3.min_cards_red_3 away_cards_red_min_last_3
,t3.avg_penalty_won_3 away_penalty_won_avg_last_3
,t3.max_penalty_won_3 away_penalty_won_max_last_3
,t3.min_penalty_won_3 away_penalty_won_min_last_3
,t3.avg_penalty_commited_3 away_penalty_commited_avg_last_3
,t3.max_penalty_commited_3 away_penalty_commited_max_last_3
,t3.min_penalty_commited_3 away_penalty_commited_min_last_3
,t3.avg_penalty_scored_3 away_penalty_scored_avg_last_3
,t3.max_penalty_scored_3 away_penalty_scored_max_last_3
,t3.min_penalty_scored_3 away_penalty_scored_min_last_3
,t3.avg_penalty_missed_3 away_penalty_missed_avg_last_3
,t3.max_penalty_missed_3 away_penalty_missed_max_last_3
,t3.min_penalty_missed_3 away_penalty_missed_min_last_3
,t3.avg_penalty_saved_3 away_penalty_saved_avg_last_3
,t3.max_penalty_saved_3 away_penalty_saved_max_last_3
,t3.min_penalty_saved_3 away_penalty_saved_min_last_3
FROM prod_match_summary_home_away_teams_id t1
LEFT JOIN transformed_prod_match_summary_total_features t2 ON t1.fixture_id = t2.fixture_id AND t1.home_team_id = t2.team_id
LEFT JOIN transformed_prod_match_summary_total_features t3 ON t1.fixture_id = t3.fixture_id AND t1.away_team_id = t3.team_id
;