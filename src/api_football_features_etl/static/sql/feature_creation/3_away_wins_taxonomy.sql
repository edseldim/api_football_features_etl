/*
AWAY-WIN TAXONOMY
=================

Run src/api_football_features_etl/static/sql/2_win_taxonomy.sql first in the
same PostgreSQL session. This script reuses its eligible population, target,
match narratives, rolling form, venue form, and H2H tables instead of rebuilding
them. Current-match narratives below are descriptive, never prediction inputs.
*/

DROP TABLE IF EXISTS away_wins_taxonomy_full_raw_consolidation CASCADE;
DROP TABLE IF EXISTS away_wins_taxonomy_team_categories CASCADE;
DROP TABLE IF EXISTS away_wins_taxonomy_features CASCADE;
DROP TABLE IF EXISTS away_wins_taxonomy_schedule CASCADE;
DROP TABLE IF EXISTS away_wins_taxonomy_lineups CASCADE;
DROP TABLE IF EXISTS away_wins_taxonomy_starting_players CASCADE;
DROP TABLE IF EXISTS away_wins_taxonomy_team_fixtures CASCADE;
DROP TABLE IF EXISTS away_wins_taxonomy_coaches CASCADE;
DROP TABLE IF EXISTS away_wins_taxonomy_context CASCADE;
DROP TABLE IF EXISTS away_wins_taxonomy_full_consolidation CASCADE;
DROP TABLE IF EXISTS transformed_prod_match_summary_away_wins_taxonomy_features CASCADE;


/* 1. New prior-only context not already present in 2_win_taxonomy.sql. */
CREATE TEMP TABLE away_wins_taxonomy_context AS
SELECT
    t.fixture_id,
    t.team_id,
    COUNT(*) OVER wprior AS prior_matches, -- amount of historical matches
    SUM(3 * t.won + t.drew) OVER wprior -- points earned in all history preceding
        / NULLIF(COUNT(*) OVER wprior, 0)::numeric AS prior_points_per_match,
    SUM(3 * t.won + t.drew) OVER w3
        / NULLIF(COUNT(*) OVER w3, 0)::numeric AS points_per_match_last_3,
    EXTRACT(EPOCH FROM (t.date - LAG(t.date) OVER wall)) / 86400.0 AS rest_days, -- rest days since last match
    COUNT(*) OVER (
        PARTITION BY t.league_id, t.team_id ORDER BY t.date
        RANGE BETWEEN INTERVAL '14 days' PRECEDING
                  AND INTERVAL '1 microsecond' PRECEDING
    ) AS matches_previous_14_days,
    COUNT(*) OVER (
        PARTITION BY t.league_id, t.team_id ORDER BY t.date
        RANGE BETWEEN INTERVAL '28 days' PRECEDING
                  AND INTERVAL '1 microsecond' PRECEDING
    ) AS matches_previous_28_days
FROM wins_taxonomy_team_match t
WINDOW
    wall AS (
        PARTITION BY league_id, team_id ORDER BY date, fixture_id
    ),
    wprior AS (
        PARTITION BY league_id, team_id ORDER BY date, fixture_id
        ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
    ),
    w3 AS (
        PARTITION BY league_id, team_id ORDER BY date, fixture_id
        ROWS BETWEEN 3 PRECEDING AND 1 PRECEDING
    );


/* 2. Coach stability. */
CREATE TEMP TABLE away_wins_taxonomy_coaches AS
WITH fixture_coach AS (
    SELECT
        t.fixture_id,
        t.date,
        t.team_id,
        MAX(c.coach_id) AS coach_id,
        MAX(c.coach_name) AS coach_name
    FROM wins_taxonomy_team_match t
    LEFT JOIN prod_teams_coaches c
      ON c.fixture_id = t.fixture_id AND c.team_id = t.team_id
    GROUP BY 1, 2, 3
), sequenced AS (
    SELECT
        f.*,
        LAG(coach_id) OVER (
            PARTITION BY team_id ORDER BY date, fixture_id
        ) AS previous_coach_id
    FROM fixture_coach f
), spells AS (
    SELECT
        s.*,
        SUM((coach_id IS NOT NULL
             AND previous_coach_id IS NOT NULL
             AND coach_id IS DISTINCT FROM previous_coach_id)::integer)
        OVER (PARTITION BY team_id ORDER BY date, fixture_id) AS coach_spell
    FROM sequenced s
)
SELECT
    fixture_id,
    team_id,
    coach_id,
    coach_name,
    (coach_id IS NOT NULL
     AND previous_coach_id IS NOT NULL
     AND coach_id IS DISTINCT FROM previous_coach_id)::integer
        AS coach_changed_this_match,
    ROW_NUMBER() OVER (
        PARTITION BY team_id, coach_spell ORDER BY date, fixture_id
    ) AS matches_under_current_coach,
    COUNT(*) FILTER (
        WHERE coach_id IS NOT NULL
          AND previous_coach_id IS NOT NULL
          AND coach_id IS DISTINCT FROM previous_coach_id
    ) OVER (
        PARTITION BY team_id ORDER BY date, fixture_id
        ROWS BETWEEN 5 PRECEDING AND 1 PRECEDING
    ) AS coach_changes_previous_5,
    (coach_id IS NOT NULL)::integer AS has_coach_data
FROM spells;


/* 3. Materialized/indexed fixture and lineup sources.
*/
CREATE TEMP TABLE away_wins_taxonomy_team_fixtures AS
SELECT
    fixture_id,
    date,
    team_id,
    ROW_NUMBER() OVER (
        PARTITION BY team_id ORDER BY date, fixture_id
    ) AS fixture_number
FROM wins_taxonomy_team_match;

CREATE UNIQUE INDEX ON away_wins_taxonomy_team_fixtures
    (team_id, fixture_number);
CREATE INDEX ON away_wins_taxonomy_team_fixtures (fixture_id, team_id);

CREATE TEMP TABLE away_wins_taxonomy_starting_players AS
SELECT DISTINCT l.fixture_id, l.team_id, l.player_id
FROM prod_match_lineups l
INNER JOIN wins_taxonomy_team_match t
  ON t.fixture_id = l.fixture_id AND t.team_id = l.team_id
WHERE l.is_starting IS TRUE AND l.player_id IS NOT NULL;

CREATE UNIQUE INDEX ON away_wins_taxonomy_starting_players
    (team_id, fixture_id, player_id);


/* 4. Starting-XI continuity and missing-regular proxies. */
CREATE TEMP TABLE away_wins_taxonomy_lineups AS
WITH fixture_lineups AS (
    SELECT
        t.fixture_id,
        t.date,
        t.team_id,
        t.fixture_number,
        ARRAY_AGG(p.player_id ORDER BY p.player_id)
            FILTER (WHERE p.player_id IS NOT NULL) AS starters, -- group players in array
        COUNT(p.player_id) AS starting_xi_size
    FROM away_wins_taxonomy_team_fixtures t
    LEFT JOIN away_wins_taxonomy_starting_players p
      ON p.fixture_id = t.fixture_id AND p.team_id = t.team_id
    GROUP BY 1, 2, 3, 4
), previous_lineups AS (
    SELECT
        f.*,
        LAG(starters) OVER (
            PARTITION BY team_id ORDER BY fixture_number
        ) AS previous_starters
    FROM fixture_lineups f
), recent_player_starts AS (
    SELECT
        current_fixture.fixture_id,
        current_fixture.team_id,
        player.player_id,
        COUNT(*) AS previous_starts -- players that have been present in at least 1 of the last 5 matches (not counting the current match)
    FROM away_wins_taxonomy_team_fixtures current_fixture
    INNER JOIN away_wins_taxonomy_team_fixtures history_fixture
      ON history_fixture.team_id = current_fixture.team_id
     AND history_fixture.fixture_number BETWEEN
         current_fixture.fixture_number - 5 AND current_fixture.fixture_number - 1
    INNER JOIN away_wins_taxonomy_starting_players player
      ON player.fixture_id = history_fixture.fixture_id
     AND player.team_id = history_fixture.team_id
    GROUP BY 1, 2, 3
), regulars AS (
    SELECT
        current_lineup.fixture_id,
        current_lineup.team_id,
        COUNT(*) FILTER (WHERE history.previous_starts >= 3)
            AS recent_regulars, -- players that have been in at least 3 past matches
        COUNT(*) FILTER (
            WHERE history.previous_starts >= 3
              AND NOT (history.player_id = ANY(
                  COALESCE(current_lineup.starters, ARRAY[]::bigint[])
              )) -- players that have been in at least 3 past matches and are not in the current lineup
        ) AS missing_recent_regulars,
        SUM(history.previous_starts) FILTER (
            WHERE NOT (history.player_id = ANY(
                COALESCE(current_lineup.starters, ARRAY[]::bigint[])
            ))
        ) AS missing_starter_importance -- sum of regularity of missing starters, to proxy for the importance of missing players (if a team is playing with subtitutes then this number will be higher than if they are playing with their regular starters)
    FROM previous_lineups current_lineup
    LEFT JOIN recent_player_starts history
      ON history.fixture_id = current_lineup.fixture_id
     AND history.team_id = current_lineup.team_id
    GROUP BY 1, 2
)
SELECT
    f.fixture_id,
    f.team_id,
    f.starting_xi_size,
    CASE WHEN f.starters IS NOT NULL AND f.previous_starters IS NOT NULL THEN
        1 - (SELECT COUNT(*)
             FROM UNNEST(f.starters) player_id
             WHERE player_id = ANY(f.previous_starters)) / 11.0
    END AS lineup_disruption, -- amount of change in the starting XI compared to the previous match (0 = no change, 1 = completely different lineup)
    CASE WHEN f.starting_xi_size > 0 THEN r.recent_regulars END
        AS recent_regulars,
    CASE WHEN f.starting_xi_size > 0 THEN r.missing_recent_regulars END
        AS missing_recent_regulars,
    CASE WHEN f.starting_xi_size > 0 THEN r.missing_starter_importance END
        AS missing_starter_importance,
    (f.starting_xi_size > 0)::integer AS has_lineup_data
FROM previous_lineups f
LEFT JOIN regulars r USING (fixture_id, team_id);


/* 5. Observed future congestion.*/
CREATE TEMP TABLE away_wins_taxonomy_schedule AS
WITH next_fixtures AS (
    SELECT
        fixture_id,
        team_id,
        date,
        LEAD(date, 1) OVER w AS next_date_1,
        LEAD(date, 2) OVER w AS next_date_2,
        LEAD(date, 3) OVER w AS next_date_3
    FROM wins_taxonomy_team_match
    WINDOW w AS (
        PARTITION BY team_id ORDER BY date, fixture_id
    )
)
SELECT
    fixture_id,
    team_id,
    EXTRACT(EPOCH FROM (next_date_1 - date)) / 86400.0
        AS days_until_next_fixture,
    (COALESCE(next_date_1 <= date + INTERVAL '21 days', FALSE)::integer
     + COALESCE(next_date_2 <= date + INTERVAL '21 days', FALSE)::integer
     + COALESCE(next_date_3 <= date + INTERVAL '21 days', FALSE)::integer)
        AS fixtures_next_21_days
FROM next_fixtures;

/* 6. Away-win extension of the reusable final feature table. */
CREATE TABLE away_wins_taxonomy_features AS
SELECT
    base.*,
    (base.target = 2)::integer AS away_win,

    hc.prior_matches AS home_prior_matches,
    ac.prior_matches AS away_prior_matches,
    hc.prior_points_per_match AS home_prior_points_per_match,
    ac.prior_points_per_match AS away_prior_points_per_match,
    hc.points_per_match_last_3 AS home_points_per_match_last_3,
    ac.points_per_match_last_3 AS away_points_per_match_last_3,
    hc.rest_days AS home_rest_days,
    ac.rest_days AS away_rest_days,
    hc.matches_previous_14_days AS home_matches_previous_14_days,
    ac.matches_previous_14_days AS away_matches_previous_14_days,

    hcoach.coach_changed_this_match AS home_coach_changed,
    acoach.coach_changed_this_match AS away_coach_changed,
    hcoach.matches_under_current_coach AS home_matches_under_current_coach,
    acoach.matches_under_current_coach AS away_matches_under_current_coach,
    hcoach.coach_changes_previous_5 AS home_coach_changes_previous_5,
    acoach.coach_changes_previous_5 AS away_coach_changes_previous_5,

    hl.lineup_disruption AS home_lineup_disruption,
    al.lineup_disruption AS away_lineup_disruption,
    hl.missing_recent_regulars AS home_missing_recent_regulars,
    al.missing_recent_regulars AS away_missing_recent_regulars,
    hl.missing_starter_importance AS home_missing_starter_importance,
    al.missing_starter_importance AS away_missing_starter_importance,

    hs.days_until_next_fixture AS home_days_until_next_fixture,
    aws.days_until_next_fixture AS away_days_until_next_fixture,
    hs.fixtures_next_21_days AS home_fixtures_next_21_days,
    aws.fixtures_next_21_days AS away_fixtures_next_21_days,

    /* Central relative features. */
    base.away_goal_difference_avg_last_5
        - base.home_goal_difference_avg_last_5 AS relative_strength_advantage,
    base.away_xg_difference_avg_last_5
        - base.home_xg_difference_avg_last_5 AS underlying_performance_advantage,
    base.away_win_rate_last_5
        - base.home_win_rate_last_5 AS away_form_advantage,
    hc.points_per_match_last_3
        - (3 * base.home_win_rate_last_10 + base.home_draw_rate_last_10) -- points per last 10 matches
        AS home_form_trend, -- recent home form trend (positive = improving, negative = declining)
    ac.points_per_match_last_3
        - (3 * base.away_win_rate_last_10 + base.away_draw_rate_last_10)
        AS away_form_trend,
    ac.rest_days - hc.rest_days AS away_rest_advantage,
    hc.matches_previous_14_days - ac.matches_previous_14_days
        AS away_congestion_advantage,
    /* Missing operational data is unknown, not zero disruption/change. */
    CASE
        WHEN hl.has_lineup_data = 1 AND al.has_lineup_data = 1
        THEN hl.missing_recent_regulars - al.missing_recent_regulars
    END AS away_lineup_advantage,
    CASE
        WHEN hcoach.has_coach_data = 1 AND acoach.has_coach_data = 1
        THEN hcoach.coach_changes_previous_5
             - acoach.coach_changes_previous_5
    END AS away_coach_stability_advantage,
    CASE
        WHEN hs.days_until_next_fixture IS NOT NULL
         AND aws.days_until_next_fixture IS NOT NULL
        THEN hs.fixtures_next_21_days - aws.fixtures_next_21_days
    END AS away_future_schedule_advantage,

    /* Retrospective away-win paths; not model inputs. */
    ml.scoreline_category,
    (base.target = 2 AND ABS(ml.home_goals - ml.away_goals) = 1)::integer
        AS narrow_away_win,
    (base.target = 2 AND ml.has_red_card)::integer AS card_affected_away_win,
    (base.target = 2 AND ml.has_late_decisive_goal)::integer AS late_away_win,
    (base.target = 2 AND ml.has_decisive_penalty)::integer
        AS penalty_affected_away_win,
    (base.target = 2 AND ml.has_decisive_own_goal)::integer
        AS own_goal_affected_away_win,

    hcoach.has_coach_data AS home_has_coach_data,
    acoach.has_coach_data AS away_has_coach_data,
    hl.has_lineup_data AS home_has_lineup_data,
    al.has_lineup_data AS away_has_lineup_data
FROM transformed_prod_match_summary_win_taxonomy_features base
LEFT JOIN away_wins_taxonomy_context hc
  ON hc.fixture_id = base.fixture_id AND hc.team_id = base.home_team_id
LEFT JOIN away_wins_taxonomy_context ac
  ON ac.fixture_id = base.fixture_id AND ac.team_id = base.away_team_id
LEFT JOIN away_wins_taxonomy_coaches hcoach
  ON hcoach.fixture_id = base.fixture_id AND hcoach.team_id = base.home_team_id
LEFT JOIN away_wins_taxonomy_coaches acoach
  ON acoach.fixture_id = base.fixture_id AND acoach.team_id = base.away_team_id
LEFT JOIN away_wins_taxonomy_lineups hl
  ON hl.fixture_id = base.fixture_id AND hl.team_id = base.home_team_id
LEFT JOIN away_wins_taxonomy_lineups al
  ON al.fixture_id = base.fixture_id AND al.team_id = base.away_team_id
LEFT JOIN away_wins_taxonomy_schedule hs
  ON hs.fixture_id = base.fixture_id AND hs.team_id = base.home_team_id
LEFT JOIN away_wins_taxonomy_schedule aws
  ON aws.fixture_id = base.fixture_id AND aws.team_id = base.away_team_id
LEFT JOIN wins_taxonomy_match_level ml
  ON ml.fixture_id = base.fixture_id
WHERE base.league_season >= 2021;


/* 7. Prior-only tenure and strength categories. */
CREATE TEMP TABLE away_wins_taxonomy_team_categories AS
SELECT
    fixture_id,
    team_id,
    prior_matches AS total_matches,
    prior_points_per_match AS points_per_match,
    CASE
        WHEN prior_matches < 5 THEN 'cold_start'
        WHEN prior_matches < 20 THEN 'not_consolidated'
        WHEN prior_matches < 50 THEN 'consolidated'
        ELSE 'high_tenure'
    END AS consolidation_category,
    CASE
        WHEN prior_matches < 5 THEN 'insufficient_history'
        WHEN prior_points_per_match < 1.00 THEN 'lower_strength'
        WHEN prior_points_per_match < 1.50 THEN 'middle_strength'
        ELSE 'higher_strength'
    END AS strength_category
FROM away_wins_taxonomy_context;

CREATE TEMP TABLE away_wins_taxonomy_full_raw_consolidation AS
SELECT
    f.*,
    hcat.consolidation_category AS home_consolidation_category,
    acat.consolidation_category AS away_consolidation_category,
    hcat.strength_category AS home_strength_category,
    acat.strength_category AS away_strength_category
FROM away_wins_taxonomy_features f
LEFT JOIN away_wins_taxonomy_team_categories hcat
  ON hcat.fixture_id = f.fixture_id AND hcat.team_id = f.home_team_id
LEFT JOIN away_wins_taxonomy_team_categories acat
  ON acat.fixture_id = f.fixture_id AND acat.team_id = f.away_team_id;

CREATE TEMP TABLE away_wins_taxonomy_full_consolidation AS
SELECT
fixture_id
,date
,league_id
,league_season
,league_round
,venue_id
,venue_name
,home_team_id
,away_team_id
,target
,home_prior_matches
,away_prior_matches
,home_prior_points_per_match
,away_prior_points_per_match
,home_points_per_match_last_3
,away_points_per_match_last_3
,home_rest_days
,away_rest_days
,home_matches_previous_14_days
,away_matches_previous_14_days
,home_coach_changed
,away_coach_changed
,home_matches_under_current_coach
,away_matches_under_current_coach
,home_coach_changes_previous_5
,away_coach_changes_previous_5
,home_lineup_disruption
,away_lineup_disruption
,home_missing_recent_regulars
,away_missing_recent_regulars
,home_missing_starter_importance
,away_missing_starter_importance
,home_days_until_next_fixture
,away_days_until_next_fixture
,home_fixtures_next_21_days
,away_fixtures_next_21_days
,relative_strength_advantage
,underlying_performance_advantage
,away_form_advantage
,home_form_trend
,away_form_trend
,away_rest_advantage
,away_congestion_advantage
,away_lineup_advantage
,away_coach_stability_advantage
,away_future_schedule_advantage
FROM away_wins_taxonomy_full_raw_consolidation;

CREATE TABLE transformed_prod_match_summary_away_wins_taxonomy_features AS
SELECT
fixture_id
,date
,league_id
,league_season
,league_round
,venue_id
,venue_name
,home_team_id
,away_team_id
,target
,LAG(home_prior_matches) OVER w3h AS home_prior_matches_lag_1
,LAG(away_prior_matches) OVER w3a AS away_prior_matches_lag_1
,LAG(home_prior_points_per_match) OVER w3h AS home_prior_points_per_match_lag_1
,LAG(away_prior_points_per_match) OVER w3a AS away_prior_points_per_match_lag_1
,LAG(home_points_per_match_last_3) OVER w3h AS home_points_per_match_last_3_lag_1
,LAG(away_points_per_match_last_3) OVER w3a AS away_points_per_match_last_3_lag_1
,LAG(home_rest_days) OVER w3h AS home_rest_days_lag_1
,LAG(away_rest_days) OVER w3a AS away_rest_days_lag_1
,LAG(home_matches_previous_14_days) OVER w3h AS home_matches_previous_14_days_lag_1
,LAG(away_matches_previous_14_days) OVER w3a AS away_matches_previous_14_days_lag_1
,LAG(home_coach_changed) OVER w3h AS home_coach_changed_lag_1
,LAG(away_coach_changed) OVER w3a AS away_coach_changed_lag_1
,LAG(home_matches_under_current_coach) OVER w3h AS home_matches_under_current_coach_lag_1
,LAG(away_matches_under_current_coach) OVER w3a AS away_matches_under_current_coach_lag_1
,LAG(home_coach_changes_previous_5) OVER w3h AS home_coach_changes_previous_5_lag_1
,LAG(away_coach_changes_previous_5) OVER w3a AS away_coach_changes_previous_5_lag_1
,LAG(home_lineup_disruption) OVER w3h AS home_lineup_disruption_lag_1
,LAG(away_lineup_disruption) OVER w3a AS away_lineup_disruption_lag_1
,LAG(home_missing_recent_regulars) OVER w3h AS home_missing_recent_regulars_lag_1
,LAG(away_missing_recent_regulars) OVER w3a AS away_missing_recent_regulars_lag_1
,LAG(home_missing_starter_importance) OVER w3h AS home_missing_starter_importance_lag_1
,LAG(away_missing_starter_importance) OVER w3a AS away_missing_starter_importance_lag_1
,LAG(relative_strength_advantage) OVER w3h AS relative_strength_advantage_lag_1
,LAG(underlying_performance_advantage) OVER w3h AS underlying_performance_advantage_lag_1
,LAG(away_form_advantage) OVER w3a AS away_form_advantage_lag_1
,LAG(home_form_trend) OVER w3h AS home_form_trend_lag_1
,LAG(away_form_trend) OVER w3a AS away_form_trend_lag_1
,LAG(away_rest_advantage) OVER w3a AS away_rest_advantage_lag_1
,LAG(away_congestion_advantage) OVER w3a AS away_congestion_advantage_lag_1
,LAG(away_lineup_advantage) OVER w3a AS away_lineup_advantage_lag_1
,LAG(away_coach_stability_advantage) OVER w3a AS away_coach_stability_advantage_lag_1
,LAG(away_future_schedule_advantage) OVER w3a AS away_future_schedule_advantage_lag_1

,LAG(home_prior_matches,2) OVER w3h AS home_prior_matches_lag_2
,LAG(away_prior_matches,2) OVER w3a AS away_prior_matches_lag_2
,LAG(home_prior_points_per_match,2) OVER w3h AS home_prior_points_per_match_lag_2
,LAG(away_prior_points_per_match,2) OVER w3a AS away_prior_points_per_match_lag_2
,LAG(home_points_per_match_last_3,2) OVER w3h AS home_points_per_match_last_3_lag_2
,LAG(away_points_per_match_last_3,2) OVER w3a AS away_points_per_match_last_3_lag_2
,LAG(home_rest_days,2) OVER w3h AS home_rest_days_lag_2
,LAG(away_rest_days,2) OVER w3a AS away_rest_days_lag_2
,LAG(home_matches_previous_14_days,2) OVER w3h AS home_matches_previous_14_days_lag_2
,LAG(away_matches_previous_14_days,2) OVER w3a AS away_matches_previous_14_days_lag_2
,LAG(home_coach_changed,2) OVER w3h AS home_coach_changed_lag_2
,LAG(away_coach_changed,2) OVER w3a AS away_coach_changed_lag_2
,LAG(home_matches_under_current_coach,2) OVER w3h AS home_matches_under_current_coach_lag_2
,LAG(away_matches_under_current_coach,2) OVER w3a AS away_matches_under_current_coach_lag_2
,LAG(home_coach_changes_previous_5,2) OVER w3h AS home_coach_changes_previous_5_lag_2
,LAG(away_coach_changes_previous_5,2) OVER w3a AS away_coach_changes_previous_5_lag_2
,LAG(home_lineup_disruption,2) OVER w3h AS home_lineup_disruption_lag_2
,LAG(away_lineup_disruption,2) OVER w3a AS away_lineup_disruption_lag_2
,LAG(home_missing_recent_regulars,2) OVER w3h AS home_missing_recent_regulars_lag_2
,LAG(away_missing_recent_regulars,2) OVER w3a AS away_missing_recent_regulars_lag_2
,LAG(home_missing_starter_importance,2) OVER w3h AS home_missing_starter_importance_lag_2
,LAG(away_missing_starter_importance,2) OVER w3a AS away_missing_starter_importance_lag_2
,LAG(relative_strength_advantage,2) OVER w3h AS relative_strength_advantage_lag_2
,LAG(underlying_performance_advantage,2) OVER w3h AS underlying_performance_advantage_lag_2
,LAG(away_form_advantage,2) OVER w3a AS away_form_advantage_lag_2
,LAG(home_form_trend,2) OVER w3h AS home_form_trend_lag_2
,LAG(away_form_trend,2) OVER w3a AS away_form_trend_lag_2
,LAG(away_rest_advantage,2) OVER w3a AS away_rest_advantage_lag_2
,LAG(away_congestion_advantage,2) OVER w3a AS away_congestion_advantage_lag_2
,LAG(away_lineup_advantage,2) OVER w3a AS away_lineup_advantage_lag_2
,LAG(away_coach_stability_advantage,2) OVER w3a AS away_coach_stability_advantage_lag_2
,LAG(away_future_schedule_advantage,2) OVER w3a AS away_future_schedule_advantage_lag_2

,LAG(home_prior_matches,3) OVER w3h AS home_prior_matches_lag_3
,LAG(away_prior_matches,3) OVER w3a AS away_prior_matches_lag_3
,LAG(home_prior_points_per_match,3) OVER w3h AS home_prior_points_per_match_lag_3
,LAG(away_prior_points_per_match,3) OVER w3a AS away_prior_points_per_match_lag_3
,LAG(home_points_per_match_last_3,3) OVER w3h AS home_points_per_match_last_3_lag_3
,LAG(away_points_per_match_last_3,3) OVER w3a AS away_points_per_match_last_3_lag_3
,LAG(home_rest_days,3) OVER w3h AS home_rest_days_lag_3
,LAG(away_rest_days,3) OVER w3a AS away_rest_days_lag_3
,LAG(home_matches_previous_14_days,3) OVER w3h AS home_matches_previous_14_days_lag_3
,LAG(away_matches_previous_14_days,3) OVER w3a AS away_matches_previous_14_days_lag_3
,LAG(home_coach_changed,3) OVER w3h AS home_coach_changed_lag_3
,LAG(away_coach_changed,3) OVER w3a AS away_coach_changed_lag_3
,LAG(home_matches_under_current_coach,3) OVER w3h AS home_matches_under_current_coach_lag_3
,LAG(away_matches_under_current_coach,3) OVER w3a AS away_matches_under_current_coach_lag_3
,LAG(home_coach_changes_previous_5,3) OVER w3h AS home_coach_changes_previous_5_lag_3
,LAG(away_coach_changes_previous_5,3) OVER w3a AS away_coach_changes_previous_5_lag_3
,LAG(home_lineup_disruption,3) OVER w3h AS home_lineup_disruption_lag_3
,LAG(away_lineup_disruption,3) OVER w3a AS away_lineup_disruption_lag_3
,LAG(home_missing_recent_regulars,3) OVER w3h AS home_missing_recent_regulars_lag_3
,LAG(away_missing_recent_regulars,3) OVER w3a AS away_missing_recent_regulars_lag_3
,LAG(home_missing_starter_importance,3) OVER w3h AS home_missing_starter_importance_lag_3
,LAG(away_missing_starter_importance,3) OVER w3a AS away_missing_starter_importance_lag_3
,LAG(relative_strength_advantage,3) OVER w3h AS relative_strength_advantage_lag_3
,LAG(underlying_performance_advantage,3) OVER w3h AS underlying_performance_advantage_lag_3
,LAG(away_form_advantage,3) OVER w3a AS away_form_advantage_lag_3
,LAG(home_form_trend,3) OVER w3h AS home_form_trend_lag_3
,LAG(away_form_trend,3) OVER w3a AS away_form_trend_lag_3
,LAG(away_rest_advantage,3) OVER w3a AS away_rest_advantage_lag_3
,LAG(away_congestion_advantage,3) OVER w3a AS away_congestion_advantage_lag_3
,LAG(away_lineup_advantage,3) OVER w3a AS away_lineup_advantage_lag_3
,LAG(away_coach_stability_advantage,3) OVER w3a AS away_coach_stability_advantage_lag_3
,LAG(away_future_schedule_advantage,3) OVER w3a AS away_future_schedule_advantage_lag_3

,AVG(home_prior_matches) OVER w3h AS home_prior_matches_avg_last_3
,AVG(away_prior_matches) OVER w3a AS away_prior_matches_avg_last_3
,AVG(home_prior_points_per_match) OVER w3h AS home_prior_points_per_match_avg_last_3
,AVG(away_prior_points_per_match) OVER w3a AS away_prior_points_per_match_avg_last_3
,AVG(home_points_per_match_last_3) OVER w3h AS home_points_per_match_last_3_avg_last_3
,AVG(away_points_per_match_last_3) OVER w3a AS away_points_per_match_last_3_avg_last_3
,AVG(home_rest_days) OVER w3h AS home_rest_days_avg_last_3
,AVG(away_rest_days) OVER w3a AS away_rest_days_avg_last_3
,AVG(home_matches_previous_14_days) OVER w3h AS home_matches_previous_14_days_avg_last_3
,AVG(away_matches_previous_14_days) OVER w3a AS away_matches_previous_14_days_avg_last_3
,AVG(home_coach_changed) OVER w3h AS home_coach_changed_avg_last_3
,AVG(away_coach_changed) OVER w3a AS away_coach_changed_avg_last_3
,AVG(home_matches_under_current_coach) OVER w3h AS home_matches_under_current_coach_avg_last_3
,AVG(away_matches_under_current_coach) OVER w3a AS away_matches_under_current_coach_avg_last_3
,AVG(home_coach_changes_previous_5) OVER w3h AS home_coach_changes_previous_5_avg_last_3
,AVG(away_coach_changes_previous_5) OVER w3a AS away_coach_changes_previous_5_avg_last_3
,AVG(home_lineup_disruption) OVER w3h AS home_lineup_disruption_avg_last_3
,AVG(away_lineup_disruption) OVER w3a AS away_lineup_disruption_avg_last_3
,AVG(home_missing_recent_regulars) OVER w3h AS home_missing_recent_regulars_avg_last_3
,AVG(away_missing_recent_regulars) OVER w3a AS away_missing_recent_regulars_avg_last_3
,AVG(home_missing_starter_importance) OVER w3h AS home_missing_starter_importance_avg_last_3
,AVG(away_missing_starter_importance) OVER w3a AS away_missing_starter_importance_avg_last_3
,AVG(relative_strength_advantage) OVER w3h AS relative_strength_advantage_avg_last_3
,AVG(underlying_performance_advantage) OVER w3h AS underlying_performance_advantage_avg_last_3
,AVG(away_form_advantage) OVER w3a AS away_form_advantage_avg_last_3
,AVG(home_form_trend) OVER w3h AS home_form_trend_avg_last_3
,AVG(away_form_trend) OVER w3a AS away_form_trend_avg_last_3
,AVG(away_rest_advantage) OVER w3a AS away_rest_advantage_avg_last_3
,AVG(away_congestion_advantage) OVER w3a AS away_congestion_advantage_avg_last_3
,AVG(away_lineup_advantage) OVER w3a AS away_lineup_advantage_avg_last_3
,AVG(away_coach_stability_advantage) OVER w3a AS away_coach_stability_advantage_avg_last_3
,AVG(away_future_schedule_advantage) OVER w3a AS away_future_schedule_advantage_avg_last_3

,AVG(home_prior_matches) OVER w5h AS home_prior_matches_avg_last_5
,AVG(away_prior_matches) OVER w5a AS away_prior_matches_avg_last_5
,AVG(home_prior_points_per_match) OVER w5h AS home_prior_points_per_match_avg_last_5
,AVG(away_prior_points_per_match) OVER w5a AS away_prior_points_per_match_avg_last_5
,AVG(home_points_per_match_last_3) OVER w5h AS home_points_per_match_last_3_avg_last_5
,AVG(away_points_per_match_last_3) OVER w5a AS away_points_per_match_last_3_avg_last_5
,AVG(home_rest_days) OVER w5h AS home_rest_days_avg_last_5
,AVG(away_rest_days) OVER w5a AS away_rest_days_avg_last_5
,AVG(home_matches_previous_14_days) OVER w5h AS home_matches_previous_14_days_avg_last_5
,AVG(away_matches_previous_14_days) OVER w5a AS away_matches_previous_14_days_avg_last_5
,AVG(home_coach_changed) OVER w5h AS home_coach_changed_avg_last_5
,AVG(away_coach_changed) OVER w5a AS away_coach_changed_avg_last_5
,AVG(home_matches_under_current_coach) OVER w5h AS home_matches_under_current_coach_avg_last_5
,AVG(away_matches_under_current_coach) OVER w5a AS away_matches_under_current_coach_avg_last_5
,AVG(home_coach_changes_previous_5) OVER w5h AS home_coach_changes_previous_5_avg_last_5
,AVG(away_coach_changes_previous_5) OVER w5a AS away_coach_changes_previous_5_avg_last_5
,AVG(home_lineup_disruption) OVER w5h AS home_lineup_disruption_avg_last_5
,AVG(away_lineup_disruption) OVER w5a AS away_lineup_disruption_avg_last_5
,AVG(home_missing_recent_regulars) OVER w5h AS home_missing_recent_regulars_avg_last_5
,AVG(away_missing_recent_regulars) OVER w5a AS away_missing_recent_regulars_avg_last_5
,AVG(home_missing_starter_importance) OVER w5h AS home_missing_starter_importance_avg_last_5
,AVG(away_missing_starter_importance) OVER w5a AS away_missing_starter_importance_avg_last_5
,AVG(relative_strength_advantage) OVER w5h AS relative_strength_advantage_avg_last_5
,AVG(underlying_performance_advantage) OVER w5h AS underlying_performance_advantage_avg_last_5
,AVG(away_form_advantage) OVER w5a AS away_form_advantage_avg_last_5
,AVG(home_form_trend) OVER w5h AS home_form_trend_avg_last_5
,AVG(away_form_trend) OVER w5a AS away_form_trend_avg_last_5
,AVG(away_rest_advantage) OVER w5a AS away_rest_advantage_avg_last_5
,AVG(away_congestion_advantage) OVER w5a AS away_congestion_advantage_avg_last_5
,AVG(away_lineup_advantage) OVER w5a AS away_lineup_advantage_avg_last_5
,AVG(away_coach_stability_advantage) OVER w5a AS away_coach_stability_advantage_avg_last_5
,AVG(away_future_schedule_advantage) OVER w5a AS away_future_schedule_advantage_avg_last_5
FROM away_wins_taxonomy_full_consolidation
WINDOW 
    w3h AS (
    PARTITION BY league_id, home_team_id
    ORDER BY date, fixture_id
    ROWS BETWEEN 3 PRECEDING AND 1 PRECEDING
    ),
    w5h AS (
    PARTITION BY league_id, home_team_id
    ORDER BY date, fixture_id
    ROWS BETWEEN 5 PRECEDING AND 1 PRECEDING
    ),
    w3a AS (
    PARTITION BY league_id, away_team_id
    ORDER BY date, fixture_id
    ROWS BETWEEN 3 PRECEDING AND 1 PRECEDING
    ),
    w5a AS (
    PARTITION BY league_id, away_team_id
    ORDER BY date, fixture_id
    ROWS BETWEEN 5 PRECEDING AND 1 PRECEDING
    );



