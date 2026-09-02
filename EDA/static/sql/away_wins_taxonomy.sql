/*
AWAY-WIN TAXONOMY
=================

Run src/api_football_features_etl/static/sql/2_win_taxonomy.sql first in the
same PostgreSQL session. This script reuses its eligible population, target,
match narratives, rolling form, venue form, and H2H tables instead of rebuilding
them. Current-match narratives below are descriptive, never prediction inputs.
*/

DROP VIEW IF EXISTS away_wins_taxonomy_analysis CASCADE;
DROP TABLE IF EXISTS away_wins_taxonomy_team_categories CASCADE;
DROP TABLE IF EXISTS away_wins_taxonomy_features CASCADE;
DROP TABLE IF EXISTS away_wins_taxonomy_schedule CASCADE;
DROP TABLE IF EXISTS away_wins_taxonomy_lineups CASCADE;
DROP TABLE IF EXISTS away_wins_taxonomy_starting_players CASCADE;
DROP TABLE IF EXISTS away_wins_taxonomy_team_fixtures CASCADE;
DROP TABLE IF EXISTS away_wins_taxonomy_coaches CASCADE;
DROP TABLE IF EXISTS away_wins_taxonomy_context CASCADE;


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

CREATE VIEW away_wins_taxonomy_analysis AS
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


/* ========================================================================
ANALYSIS OUTPUTS
======================================================================== */

/* A. Away-win prevalence by tenure pairing. */
SELECT
    home_consolidation_category,
    away_consolidation_category,
    COUNT(*) AS matches,
    SUM(away_win) AS away_wins,
    ROUND(100.0 * AVG(away_win), 2) AS away_win_pct
FROM away_wins_taxonomy_analysis
GROUP BY 1, 2
ORDER BY 1, 2;


/* B. Tenure crossed with strength. */
SELECT
    home_consolidation_category,
    home_strength_category,
    away_consolidation_category,
    away_strength_category,
    COUNT(*) AS matches,
    SUM(away_win) AS away_wins,
    ROUND(100.0 * AVG(away_win), 2) AS away_win_pct
FROM away_wins_taxonomy_analysis
GROUP BY 1, 2, 3, 4
HAVING COUNT(*) >= 20
ORDER BY away_win_pct DESC, matches DESC;

/* C. Feature means: away wins versus all other outcomes. */
SELECT
    CASE WHEN away_win = 1 THEN 'away_win' ELSE 'not_away_win' END
        AS outcome_group,
    COUNT(*) AS matches,
    ROUND(AVG(relative_strength_advantage)::numeric, 3)
        AS relative_strength_advantage,
    ROUND(AVG(underlying_performance_advantage)::numeric, 3)
        AS underlying_performance_advantage,
    ROUND(AVG(away_form_advantage)::numeric, 3) AS away_form_advantage,
    ROUND(AVG(home_form_trend)::numeric, 3) AS home_form_trend,
    ROUND(AVG(away_form_trend)::numeric, 3) AS away_form_trend,
    ROUND(AVG(away_lineup_advantage)::numeric, 3) AS away_lineup_advantage,
    ROUND(AVG(away_coach_stability_advantage)::numeric, 3)
        AS away_coach_stability_advantage,
    ROUND(AVG(away_rest_advantage)::numeric, 2) AS away_rest_advantage,
    ROUND(AVG(away_congestion_advantage)::numeric, 2)
        AS away_congestion_advantage,
    ROUND(AVG(away_future_schedule_advantage)::numeric, 2)
        AS away_future_schedule_advantage,
    COUNT(relative_strength_advantage) AS relative_strength_n,
    ROUND(STDDEV_SAMP(relative_strength_advantage)::numeric, 3)
        AS relative_strength_sd,
    COUNT(underlying_performance_advantage) AS underlying_performance_n,
    ROUND(STDDEV_SAMP(underlying_performance_advantage)::numeric, 3)
        AS underlying_performance_sd,
    COUNT(away_form_advantage) AS away_form_n,
    ROUND(STDDEV_SAMP(away_form_advantage)::numeric, 3) AS away_form_sd,
    COUNT(away_lineup_advantage) AS lineup_advantage_n,
    COUNT(away_coach_stability_advantage) AS coach_stability_n,
    COUNT(away_rest_advantage) AS rest_advantage_n,
    COUNT(away_future_schedule_advantage) AS future_schedule_n
FROM away_wins_taxonomy_analysis
GROUP BY 1
ORDER BY 1;

/* D. Each hypothesis active versus inactive. */
WITH hypotheses AS (
    SELECT fixture_id, away_win, 'home_bad_form' AS hypothesis,
           home_form_trend < -0.50 AS active
    FROM away_wins_taxonomy_analysis
    UNION ALL
    SELECT fixture_id, away_win, 'away_good_form', away_form_trend > 0.50
    FROM away_wins_taxonomy_analysis
    UNION ALL
    SELECT fixture_id, away_win, 'home_recent_coach_change',
           CASE
               WHEN home_has_coach_data = 1 AND away_has_coach_data = 1
               THEN home_coach_changed = 1
                    OR home_matches_under_current_coach <= 3
           END
    FROM away_wins_taxonomy_analysis
    UNION ALL
    SELECT fixture_id, away_win, 'home_lineup_more_disrupted',
           away_lineup_advantage > 0
    FROM away_wins_taxonomy_analysis
    UNION ALL
    SELECT fixture_id, away_win, 'away_rest_advantage',
           away_rest_advantage >= 3
    FROM away_wins_taxonomy_analysis
    UNION ALL
    SELECT fixture_id, away_win, 'away_underlying_strength_advantage',
           underlying_performance_advantage > 0.50
    FROM away_wins_taxonomy_analysis
)
SELECT
    hypothesis,
    active,
    COUNT(*) AS matches,
    SUM(away_win) AS away_wins,
    ROUND(100.0 * AVG(away_win), 2) AS away_win_pct
FROM hypotheses
WHERE active IS NOT NULL
GROUP BY 1, 2
ORDER BY 1, 2 DESC;

/* E. Retrospective away-win paths by tenure pairing. */
SELECT
    home_consolidation_category,
    away_consolidation_category,
    COUNT(*) AS away_wins,
    ROUND(100.0 * AVG(narrow_away_win), 2) AS narrow_pct,
    ROUND(100.0 * AVG(card_affected_away_win), 2) AS card_affected_pct,
    ROUND(100.0 * AVG(late_away_win), 2) AS late_pct,
    ROUND(100.0 * AVG(penalty_affected_away_win), 2)
        AS penalty_affected_pct,
    ROUND(100.0 * AVG(own_goal_affected_away_win), 2)
        AS own_goal_affected_pct
FROM away_wins_taxonomy_analysis
WHERE away_win = 1
GROUP BY 1, 2
ORDER BY 1, 2;

/* F. Temporal stability. */
SELECT
    EXTRACT(YEAR FROM date)::integer AS calendar_year,
    away_consolidation_category,
    away_strength_category,
    COUNT(*) AS away_matches,
    SUM(away_win) AS away_wins,
    ROUND(100.0 * AVG(away_win), 2) AS away_win_pct
FROM away_wins_taxonomy_analysis
GROUP BY 1, 2, 3
ORDER BY 1, 2, 3;

/* G. Coverage and cold-start audit. */
SELECT
    CASE WHEN away_win = 1 THEN 'away_win' ELSE 'not_away_win' END
        AS outcome_group,
    away_consolidation_category,
    COUNT(*) AS matches,
    ROUND(100.0 * AVG((home_has_coach_data * away_has_coach_data)::integer), 2)
        AS coach_coverage_both_pct,
    ROUND(100.0 * AVG((home_has_lineup_data * away_has_lineup_data)::integer), 2)
        AS lineup_coverage_both_pct,
    ROUND(100.0 * AVG(
        (home_matches_last_5 >= 5 AND away_matches_last_5 >= 5)::integer
    ), 2) AS full_form_history_pct
FROM away_wins_taxonomy_analysis
GROUP BY 1, 2
ORDER BY 1, 2;


/* H. Monotonicity check: away-win rate across feature quintiles.
   A useful predictive feature should generally show an ordered response. */
WITH long_features AS (
    SELECT fixture_id, away_win, 'relative_strength_advantage' AS feature,
           relative_strength_advantage AS feature_value
    FROM away_wins_taxonomy_analysis
    UNION ALL
    SELECT fixture_id, away_win, 'underlying_performance_advantage',
           underlying_performance_advantage
    FROM away_wins_taxonomy_analysis
    UNION ALL
    SELECT fixture_id, away_win, 'away_form_advantage', away_form_advantage
    FROM away_wins_taxonomy_analysis
    UNION ALL
    SELECT fixture_id, away_win, 'away_lineup_advantage',
           away_lineup_advantage::numeric
    FROM away_wins_taxonomy_analysis
    UNION ALL
    SELECT fixture_id, away_win, 'away_rest_advantage', away_rest_advantage
    FROM away_wins_taxonomy_analysis
), ranked AS (
    SELECT
        *,
        NTILE(5) OVER (PARTITION BY feature ORDER BY feature_value) AS quintile
    FROM long_features
    WHERE feature_value IS NOT NULL
)
SELECT
    feature,
    quintile,
    COUNT(*) AS matches,
    ROUND(MIN(feature_value)::numeric, 3) AS minimum,
    ROUND(MAX(feature_value)::numeric, 3) AS maximum,
    ROUND(AVG(feature_value)::numeric, 3) AS mean,
    SUM(away_win) AS away_wins,
    ROUND(100.0 * AVG(away_win), 2) AS away_win_pct,
    /* Normal-approximation standard error for quick EDA comparison. */
    ROUND((100.0 * SQRT(
        AVG(away_win) * (1 - AVG(away_win)) / COUNT(*)
    ))::numeric, 2) AS away_win_pct_se
FROM ranked
GROUP BY 1, 2
ORDER BY 1, 2;

/* I. Robust rest/congestion summaries.
   Medians and interquartile ranges are less sensitive to postponements and
   long competition breaks than the means in analysis C. */
SELECT
    CASE WHEN away_win = 1 THEN 'away_win' ELSE 'not_away_win' END
        AS outcome_group,
    COUNT(away_rest_advantage) AS rest_n,
    ROUND(AVG(away_rest_advantage)::numeric, 2) AS rest_mean,
    ROUND(PERCENTILE_CONT(0.25) WITHIN GROUP
        (ORDER BY away_rest_advantage)::numeric, 2) AS rest_p25,
    ROUND(PERCENTILE_CONT(0.50) WITHIN GROUP
        (ORDER BY away_rest_advantage)::numeric, 2) AS rest_median,
    ROUND(PERCENTILE_CONT(0.75) WITHIN GROUP
        (ORDER BY away_rest_advantage)::numeric, 2) AS rest_p75,
    COUNT(away_congestion_advantage) AS congestion_n,
    ROUND(PERCENTILE_CONT(0.50) WITHIN GROUP
        (ORDER BY away_congestion_advantage)::numeric, 2)
        AS congestion_median
FROM away_wins_taxonomy_analysis
GROUP BY 1
ORDER BY 1;

/* J. Coverage drift. Low or outcome-dependent coverage can make an apparent
   association a provider/season selection effect. */
SELECT
    EXTRACT(YEAR FROM date)::integer AS calendar_year,
    CASE WHEN away_win = 1 THEN 'away_win' ELSE 'not_away_win' END
        AS outcome_group,
    COUNT(*) AS matches,
    COUNT(underlying_performance_advantage) AS xg_history_matches,
    ROUND(100.0 * COUNT(underlying_performance_advantage)
        / NULLIF(COUNT(*), 0), 2) AS xg_history_coverage_pct,
    COUNT(away_lineup_advantage) AS lineup_matches,
    ROUND(100.0 * COUNT(away_lineup_advantage)
        / NULLIF(COUNT(*), 0), 2) AS lineup_coverage_pct,
    COUNT(away_coach_stability_advantage) AS coach_matches,
    ROUND(100.0 * COUNT(away_coach_stability_advantage)
        / NULLIF(COUNT(*), 0), 2) AS coach_coverage_pct,
    COUNT(away_future_schedule_advantage) AS future_schedule_matches,
    ROUND(100.0 * COUNT(away_future_schedule_advantage)
        / NULLIF(COUNT(*), 0), 2) AS future_schedule_coverage_pct
FROM away_wins_taxonomy_analysis
GROUP BY 1, 2
ORDER BY 1, 2;


/*
EDA CONCLUSIONS
===============

1. Relative strength is the clearest away-win signal.
   Away-win frequency rises from 18.63% in the lowest relative-strength
   quintile to 34.89% in the highest, with a broadly monotonic increase between
   them. Prior-only away-minus-home strength should therefore be a high-priority model feature.

2. Recent away-form advantage is also informative.
   Away-win frequency rises from 20.55% in the lowest form-advantage quintile
   to 32.97% in the highest. The middle quintiles are not perfectly monotonic,
   so form may work better as a nonlinear feature or through interactions with
   relative strength than as a purely linear effect.
*/
