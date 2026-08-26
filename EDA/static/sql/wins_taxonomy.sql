/*
Purpose
=======

This analysis describes the composition of match outcomes and identifies
invalid, out-of-scope, poor-quality, or historically unrepresentative
observations that may need to be excluded from the modelling dataset.

A match should not be excluded merely because its result was unusual or
difficult to predict. Valid red-card matches, penalties, own goals, late
winners, comebacks, and results against the balance of play are part of the
population that the model will encounter. Exclusion decisions should instead
be based on target validity, prediction scope, data quality, and temporal
relevance.

The taxonomy has two core analytical levels. Both levels are accompanied by
match-circumstance flags and descriptive match statistics.


Level 1: scoreline category
===========================

Scoreline provides the primary, mutually exclusive outcome category.

Decisive matches:
    - one-goal win
    - two-goal win
    - three-plus-goal win

Draws:
    - goalless draw
    - 1-1 draw
    - high-scoring draw (2-2 or higher)

Losses do not require a separate taxonomy: a home loss is the same match as
an away win. Decisive matches should therefore be described from the winner's
and loser's perspectives, while retaining whether the winner was the home or
away team.


Level 2: match-narrative flags
==============================

Narrative flags describe how the result developed. They are deliberately
non-mutually-exclusive because one match may belong to several narratives.

Candidate flags include:
    - winner scored first
    - loser scored first
    - comeback win
    - early lead established and maintained
    - late decisive goal
    - stoppage-time decisive goal
    - multiple lead changes

Every flag must have an objective SQL definition. Subjective labels such as
"early win" or "disputed win" should not be used without explicit thresholds
or observable event-based rules.


Supporting match-circumstance flags
===================================

Circumstance flags describe events or data conditions that may have affected
the result or its interpretation. Like narrative flags, they may overlap.

Candidate flags include:
    - red card and early red card
    - decisive penalty
    - decisive own goal
    - VAR intervention
    - goal disallowed
    - awarded, abandoned, or incomplete match
    - incomplete event, xG, or match-statistics data

Event timing matters. For example, an early red card at 0-0 should be
distinguished from a late red card after the result was effectively settled.


Supporting descriptive statistics
==================================

Each scoreline category and flag should be profiled using available measures
such as:
    - goals and goal margin
    - xG and xG margin
    - shots, shots on target, and their margins
    - possession and possession margin
    - goalkeeper saves
    - shot-conversion rate
    - goals minus xG
    - cards, penalties, and own goals
    - timing of the first and decisive goals
    - time spent leading, drawing, and trailing

The resulting categories should be compared by frequency, season,
competition, season stage, winner location, team concentration, and data
completeness. Raw missing values and explicit availability flags must be used
for this audit; missing statistics must not be converted to zero before the
taxonomy is constructed.

Finally, all match events and statistics in this file are retrospective
diagnostic variables. They describe the match being classified but cannot be
used as pre-match model features for that same match.
*/

/*
Implementation notes
====================

The queries below use the raw tables used by 1_league_features.sql rather than
the final feature table. The final feature table contains lagged, pre-match
features, whereas this audit needs the score, events, and statistics from the
match being described.

Objective narrative rules:
    - early permanent lead: the winner took its final, never-relinquished lead
      by minute 30;
    - late decisive goal: the winner took its final lead in minute 76 or later
      (the final 15 minutes of regulation time);
    - stoppage-time decisive goal: that goal was recorded at 90 minutes or
      later with positive added time, or with elapsed time greater than 90;
    - comeback: the eventual winner trailed after at least one valid goal;
    - multiple lead changes: leadership switched between teams at least twice.

The event-derived flags are returned as NULL when the valid recorded goals do
not reconcile with the final score. This distinguishes "false" from "unknown".

Fixture status is taken from prod_match_summary.status_short. FT, AET, and PEN
are treated as normally completed; AWD and WO are administrative results; all
other statuses are treated as not completed and are excluded from the target.
*/

DROP TABLE IF EXISTS wins_taxonomy_match_level;
CREATE TEMP TABLE wins_taxonomy_match_level AS
WITH
parameters AS
(
    SELECT
        128::integer AS league_id,
        30::integer  AS early_minute_max,
        76::integer  AS late_minute_min
),
matches AS
(
    SELECT
        m.fixture_id,
        m.date,
        EXTRACT(YEAR FROM m.date)::integer AS calendar_year,
        m.league_id,
        m.league_season,
        m.venue_id,
        m.venue_name,
        m.status_long,
        m.status_short,
        m.status_elapsed,
        m.status_extra,
        m.home_team_id,
        m.away_team_id,
        m.home_goals,
        m.away_goals,
        m.home_winner,
        m.away_winner,
        CASE
            WHEN m.home_goals > m.away_goals THEN 'home_win'
            WHEN m.home_goals < m.away_goals THEN 'away_win'
            WHEN m.home_goals = m.away_goals THEN 'draw'
        END AS outcome,
        CASE
            WHEN m.home_goals > m.away_goals THEN m.home_team_id
            WHEN m.home_goals < m.away_goals THEN m.away_team_id
        END AS winner_team_id,
        CASE
            WHEN m.home_goals > m.away_goals THEN m.away_team_id
            WHEN m.home_goals < m.away_goals THEN m.home_team_id
        END AS loser_team_id,
        CASE
            WHEN m.home_goals > m.away_goals THEN 'home'
            WHEN m.home_goals < m.away_goals THEN 'away'
        END AS winner_location,
        ABS(m.home_goals - m.away_goals) AS goal_margin,
        CASE
            WHEN m.home_goals IS NULL OR m.away_goals IS NULL
                THEN 'invalid_or_missing_score'
            WHEN m.home_goals = m.away_goals AND m.home_goals = 0
                THEN 'goalless_draw'
            WHEN m.home_goals = m.away_goals AND m.home_goals = 1
                THEN 'one_one_draw'
            WHEN m.home_goals = m.away_goals AND m.home_goals >= 2
                THEN 'high_scoring_draw'
            WHEN ABS(m.home_goals - m.away_goals) = 1
                THEN 'one_goal_win'
            WHEN ABS(m.home_goals - m.away_goals) = 2
                THEN 'two_goal_win'
            WHEN ABS(m.home_goals - m.away_goals) >= 3
                THEN 'three_plus_goal_win'
        END AS scoreline_category,
        CASE
            WHEN m.home_goals IS NULL OR m.away_goals IS NULL THEN FALSE
            WHEN m.home_goals > m.away_goals
                THEN m.home_winner IS TRUE AND m.away_winner IS FALSE
            WHEN m.home_goals < m.away_goals
                THEN m.home_winner IS FALSE AND m.away_winner IS TRUE
            ELSE
                COALESCE(m.home_winner, FALSE) IS FALSE
                AND COALESCE(m.away_winner, FALSE) IS FALSE
        END AS winner_flags_match_score,
        COALESCE(m.status_short IN ('FT', 'AET', 'PEN'), FALSE)
            AS is_normally_completed,
        COALESCE(m.status_short IN ('AWD', 'WO'), FALSE)
            AS is_administrative_result,
        (
            m.status_short IS NULL
            OR m.status_short NOT IN ('FT', 'AET', 'PEN', 'AWD', 'WO')
        ) AS is_not_completed
    FROM prod_match_summary m
    CROSS JOIN parameters p
    WHERE m.league_id = p.league_id
),
team_stats AS
(
    /* MAX(CASE ...) preserves NULL when a statistic was not supplied. */
    SELECT
        s.fixture_id,
        s.team_id,
        MAX(CASE WHEN REPLACE(TRIM(LOWER(s.stat_type)), ' ', '_') = 'shots_on_goal'
                 THEN s.stat_value END) AS shots_on_goal,
        MAX(CASE WHEN REPLACE(TRIM(LOWER(s.stat_type)), ' ', '_') = 'total_shots'
                 THEN s.stat_value END) AS total_shots,
        MAX(CASE WHEN REPLACE(TRIM(LOWER(s.stat_type)), ' ', '_') = 'ball_possession'
                 THEN s.stat_value END) AS ball_possession,
        MAX(CASE WHEN REPLACE(TRIM(LOWER(s.stat_type)), ' ', '_') = 'red_cards'
                 THEN s.stat_value END) AS red_cards,
        MAX(CASE WHEN REPLACE(TRIM(LOWER(s.stat_type)), ' ', '_') = 'yellow_cards'
                 THEN s.stat_value END) AS yellow_cards,
        MAX(CASE WHEN REPLACE(TRIM(LOWER(s.stat_type)), ' ', '_') = 'goalkeeper_saves'
                 THEN s.stat_value END) AS goalkeeper_saves,
        MAX(CASE WHEN REPLACE(TRIM(LOWER(s.stat_type)), ' ', '_') = 'expected_goals'
                 THEN s.stat_value END) AS expected_goals,
        COUNT(DISTINCT REPLACE(TRIM(LOWER(s.stat_type)), ' ', '_')) AS supplied_stat_count
    FROM prod_match_team_stats s
    INNER JOIN matches m ON m.fixture_id = s.fixture_id
    GROUP BY s.fixture_id, s.team_id
),
paired_stats AS
(
    SELECT
        m.fixture_id,
        hs.shots_on_goal AS home_shots_on_goal,
        aws.shots_on_goal AS away_shots_on_goal,
        hs.total_shots AS home_total_shots,
        aws.total_shots AS away_total_shots,
        hs.ball_possession AS home_ball_possession,
        aws.ball_possession AS away_ball_possession,
        hs.red_cards AS home_red_cards,
        aws.red_cards AS away_red_cards,
        hs.yellow_cards AS home_yellow_cards,
        aws.yellow_cards AS away_yellow_cards,
        hs.goalkeeper_saves AS home_goalkeeper_saves,
        aws.goalkeeper_saves AS away_goalkeeper_saves,
        hs.expected_goals AS home_expected_goals,
        aws.expected_goals AS away_expected_goals,
        hs.supplied_stat_count AS home_supplied_stat_count,
        aws.supplied_stat_count AS away_supplied_stat_count
    FROM matches m
    LEFT JOIN team_stats hs
        ON hs.fixture_id = m.fixture_id
       AND hs.team_id = m.home_team_id
    LEFT JOIN team_stats aws
        ON aws.fixture_id = m.fixture_id
       AND aws.team_id = m.away_team_id
),
normalised_events AS
(
    SELECT
        e.fixture_id,
        e.team_id,
        e.minute AS event_minute,
        COALESCE(e.extra, 0) AS event_extra,
        e.minute + COALESCE(e.extra, 0) AS display_minute,
        REPLACE(TRIM(LOWER(e.event_type)), ' ', '_') AS event_type,
        REPLACE(TRIM(LOWER(e.detail)), ' ', '_') AS event_detail
    FROM prod_match_events e
    INNER JOIN matches m ON m.fixture_id = e.fixture_id
),
valid_goal_events AS
(
    /* API-Football attributes own-goal events to the team awarded the goal. */
    SELECT
        e.*,
        ROW_NUMBER() OVER
        (
            PARTITION BY e.fixture_id
            ORDER BY e.event_minute, e.event_extra, e.team_id, e.event_detail
        ) AS goal_number
    FROM normalised_events e
    WHERE e.event_type = 'goal'
      AND e.event_detail IN ('normal_goal', 'penalty', 'own_goal')
),
goal_sequence AS
(
    SELECT
        g.*,
        m.home_team_id,
        m.away_team_id,
        m.winner_team_id,
        m.loser_team_id,
        COALESCE
        (
            SUM(CASE WHEN g.team_id = m.home_team_id THEN 1 ELSE 0 END) OVER
            (
                PARTITION BY g.fixture_id
                ORDER BY g.goal_number
                ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
            ), 0
        ) AS home_score_before,
        COALESCE
        (
            SUM(CASE WHEN g.team_id = m.away_team_id THEN 1 ELSE 0 END) OVER
            (
                PARTITION BY g.fixture_id
                ORDER BY g.goal_number
                ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
            ), 0
        ) AS away_score_before
    FROM valid_goal_events g
    INNER JOIN matches m ON m.fixture_id = g.fixture_id
),
goal_states AS
(
    SELECT
        g.*,
        g.home_score_before
            + CASE WHEN g.team_id = g.home_team_id THEN 1 ELSE 0 END
            AS home_score_after,
        g.away_score_before
            + CASE WHEN g.team_id = g.away_team_id THEN 1 ELSE 0 END
            AS away_score_after,
        CASE
            WHEN g.home_score_before > g.away_score_before THEN g.home_team_id
            WHEN g.away_score_before > g.home_score_before THEN g.away_team_id
        END AS leader_before,
        CASE
            WHEN g.home_score_before
                     + CASE WHEN g.team_id = g.home_team_id THEN 1 ELSE 0 END
                 > g.away_score_before
                     + CASE WHEN g.team_id = g.away_team_id THEN 1 ELSE 0 END
                THEN g.home_team_id
            WHEN g.away_score_before
                     + CASE WHEN g.team_id = g.away_team_id THEN 1 ELSE 0 END
                 > g.home_score_before
                     + CASE WHEN g.team_id = g.home_team_id THEN 1 ELSE 0 END
                THEN g.away_team_id
        END AS leader_after
    FROM goal_sequence g
),
goal_reconciliation AS
(
    SELECT
        m.fixture_id,
        COUNT(g.goal_number) AS recorded_goal_count,
        COUNT(g.goal_number) FILTER (WHERE g.team_id = m.home_team_id)
            AS recorded_home_goals,
        COUNT(g.goal_number) FILTER (WHERE g.team_id = m.away_team_id)
            AS recorded_away_goals,
        (
            COUNT(g.goal_number) FILTER (WHERE g.team_id = m.home_team_id)
                = m.home_goals
            AND
            COUNT(g.goal_number) FILTER (WHERE g.team_id = m.away_team_id)
                = m.away_goals
        ) AS goal_events_match_score
    FROM matches m
    LEFT JOIN goal_states g ON g.fixture_id = m.fixture_id
    GROUP BY m.fixture_id, m.home_goals, m.away_goals
),
narrative_raw AS
(
    SELECT
        m.fixture_id,
        MIN(g.team_id) FILTER (WHERE g.goal_number = 1) AS first_scorer_team_id,
        BOOL_OR
        (
            CASE
                WHEN m.winner_team_id = m.home_team_id
                    THEN g.home_score_after < g.away_score_after
                WHEN m.winner_team_id = m.away_team_id
                    THEN g.away_score_after < g.home_score_after
                ELSE FALSE
            END
        ) AS winner_trailed,
        COUNT(*) FILTER
        (
            WHERE g.leader_after IS NOT NULL
              AND g.leader_after IS DISTINCT FROM g.leader_before
        ) AS lead_spell_count,
        MAX(g.goal_number) FILTER
        (
            WHERE g.team_id = m.winner_team_id
              AND
              (
                  (m.winner_team_id = m.home_team_id
                   AND g.home_score_before <= g.away_score_before)
                  OR
                  (m.winner_team_id = m.away_team_id
                   AND g.away_score_before <= g.home_score_before)
              )
        ) AS decisive_goal_number
    FROM matches m
    LEFT JOIN goal_states g ON g.fixture_id = m.fixture_id
    GROUP BY m.fixture_id
),
narrative AS
(
    SELECT
        n.fixture_id,
        n.first_scorer_team_id,
        n.winner_trailed,
        n.lead_spell_count,
        d.display_minute AS decisive_goal_minute,
        d.event_minute AS decisive_goal_elapsed,
        d.event_extra AS decisive_goal_extra,
        d.event_detail AS decisive_goal_detail
    FROM narrative_raw n
    LEFT JOIN goal_states d
        ON d.fixture_id = n.fixture_id
       AND d.goal_number = n.decisive_goal_number
),
event_circumstances AS
(
    SELECT
        m.fixture_id,
        COUNT(e.fixture_id) AS event_count,
        BOOL_OR(e.event_type = 'card' AND e.event_detail = 'red_card')
            AS has_red_card,
        BOOL_OR(e.event_type = 'card' AND e.event_detail = 'red_card'
                AND e.display_minute <= p.early_minute_max) AS has_early_red_card,
        BOOL_OR(e.event_type = 'var'
                OR e.event_detail IN ('card_reviewed', 'card_upgrade',
                                      'goal_confirmed', 'penalty_confirmed'))
            AS has_var_intervention,
        BOOL_OR(e.event_detail IN ('goal_cancelled', 'goal_disallowed',
                                   'goal_disallowed_foul',
                                   'goal_disallowed_handball',
                                   'goal_disallowed_offside'))
            AS has_disallowed_goal
    FROM matches m
    CROSS JOIN parameters p
    LEFT JOIN normalised_events e ON e.fixture_id = m.fixture_id
    GROUP BY m.fixture_id
)
SELECT
    m.*,
    r.recorded_goal_count,
    r.recorded_home_goals,
    r.recorded_away_goals,
    r.goal_events_match_score,
    (
        m.is_normally_completed
        AND m.home_goals IS NOT NULL
        AND m.away_goals IS NOT NULL
        AND m.winner_flags_match_score
    ) AS is_target_eligible,
    (ec.event_count > 0) AS has_event_data,
    (ps.home_supplied_stat_count > 0 AND ps.away_supplied_stat_count > 0)
        AS has_team_stats_for_both_teams,
    (ps.home_expected_goals IS NOT NULL
     AND ps.away_expected_goals IS NOT NULL) AS has_xg_for_both_teams,

    /* Match-narrative flags: NULL means the goal sequence is unreliable. */
    CASE WHEN r.goal_events_match_score
         THEN n.first_scorer_team_id = m.winner_team_id END
        AS winner_scored_first,
    CASE WHEN r.goal_events_match_score
         THEN n.first_scorer_team_id = m.loser_team_id END
        AS loser_scored_first,
    CASE WHEN r.goal_events_match_score AND m.outcome <> 'draw'
         THEN n.winner_trailed END
        AS is_comeback_win,
    CASE WHEN r.goal_events_match_score AND m.outcome <> 'draw'
         THEN n.decisive_goal_minute <= p.early_minute_max END
        AS is_early_lead_established_and_maintained,
    CASE WHEN r.goal_events_match_score AND m.outcome <> 'draw'
         THEN n.decisive_goal_minute >= p.late_minute_min END
        AS has_late_decisive_goal,
    CASE WHEN r.goal_events_match_score AND m.outcome <> 'draw'
         THEN (n.decisive_goal_elapsed > 90
               OR (n.decisive_goal_elapsed >= 90
                   AND n.decisive_goal_extra > 0)) END
        AS has_stoppage_time_decisive_goal,
    CASE WHEN r.goal_events_match_score
         THEN GREATEST(n.lead_spell_count - 1, 0) END
        AS lead_change_count,
    CASE WHEN r.goal_events_match_score
         THEN GREATEST(n.lead_spell_count - 1, 0) >= 2 END
        AS has_multiple_lead_changes,
    n.decisive_goal_minute,

    /* Match-circumstance flags. */
    ec.has_red_card,
    ec.has_early_red_card,
    ec.has_var_intervention,
    ec.has_disallowed_goal,
    CASE WHEN r.goal_events_match_score AND m.outcome <> 'draw'
         THEN n.decisive_goal_detail = 'penalty' END
        AS has_decisive_penalty,
    CASE WHEN r.goal_events_match_score AND m.outcome <> 'draw'
         THEN n.decisive_goal_detail = 'own_goal' END
        AS has_decisive_own_goal,

    /* Raw home/away match statistics. */
    ps.home_shots_on_goal,
    ps.away_shots_on_goal,
    ps.home_total_shots,
    ps.away_total_shots,
    ps.home_ball_possession,
    ps.away_ball_possession,
    ps.home_red_cards,
    ps.away_red_cards,
    ps.home_yellow_cards,
    ps.away_yellow_cards,
    ps.home_goalkeeper_saves,
    ps.away_goalkeeper_saves,
    ps.home_expected_goals,
    ps.away_expected_goals,

    /* Winner-minus-loser measures are NULL for draws. */
    CASE WHEN m.winner_location = 'home'
         THEN ps.home_expected_goals - ps.away_expected_goals
         WHEN m.winner_location = 'away'
         THEN ps.away_expected_goals - ps.home_expected_goals END
        AS winner_xg_margin,
    CASE WHEN m.winner_location = 'home'
         THEN ps.home_total_shots - ps.away_total_shots
         WHEN m.winner_location = 'away'
         THEN ps.away_total_shots - ps.home_total_shots END
        AS winner_shot_margin,
    CASE WHEN m.winner_location = 'home'
         THEN ps.home_shots_on_goal - ps.away_shots_on_goal
         WHEN m.winner_location = 'away'
         THEN ps.away_shots_on_goal - ps.home_shots_on_goal END
        AS winner_shots_on_goal_margin,
    CASE WHEN m.winner_location = 'home'
         THEN ps.home_ball_possession - ps.away_ball_possession
         WHEN m.winner_location = 'away'
         THEN ps.away_ball_possession - ps.home_ball_possession END
        AS winner_possession_margin,
    CASE WHEN m.winner_location = 'home' AND ps.home_total_shots <> 0
         THEN m.home_goals::numeric / ps.home_total_shots
         WHEN m.winner_location = 'away' AND ps.away_total_shots <> 0
         THEN m.away_goals::numeric / ps.away_total_shots END
        AS winner_shot_conversion,
    CASE WHEN m.winner_location = 'home'
         THEN m.home_goals - ps.home_expected_goals
         WHEN m.winner_location = 'away'
         THEN m.away_goals - ps.away_expected_goals END
        AS winner_goals_minus_xg,

    /* Suggested review decision; unusual but valid matches remain included. */
    CASE
        WHEN m.home_goals IS NULL OR m.away_goals IS NULL
            THEN 'exclude_invalid_target'
        WHEN m.is_administrative_result
            THEN 'exclude_administrative_result'
        WHEN m.is_not_completed
            THEN 'exclude_not_completed'
        WHEN NOT m.winner_flags_match_score
            THEN 'review_target_inconsistency'
        WHEN NOT r.goal_events_match_score
            THEN 'keep_result_review_event_data'
        ELSE 'keep'
    END AS suggested_review_decision
FROM matches m
CROSS JOIN parameters p
LEFT JOIN paired_stats ps ON ps.fixture_id = m.fixture_id
LEFT JOIN goal_reconciliation r ON r.fixture_id = m.fixture_id
LEFT JOIN narrative n ON n.fixture_id = m.fixture_id
LEFT JOIN event_circumstances ec ON ec.fixture_id = m.fixture_id
;


/* 1. Composition of the mutually exclusive scoreline categories. */
SELECT
    scoreline_category,
    outcome,
    winner_location,
    COUNT(*) AS matches,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_all_matches
FROM wins_taxonomy_match_level
WHERE is_target_eligible
GROUP BY scoreline_category, outcome, winner_location
ORDER BY scoreline_category, outcome, winner_location;


/* 2. Narrative and circumstance prevalence by scoreline category. */
SELECT
    scoreline_category,
    COUNT(*) AS matches,
    COUNT(*) FILTER (WHERE is_comeback_win) AS comeback_wins,
    COUNT(*) FILTER (WHERE is_early_lead_established_and_maintained)
        AS early_permanent_lead_wins,
    COUNT(*) FILTER (WHERE has_late_decisive_goal) AS late_decisive_goal_wins,
    COUNT(*) FILTER (WHERE has_stoppage_time_decisive_goal)
        AS stoppage_time_decisive_goal_wins,
    COUNT(*) FILTER (WHERE has_multiple_lead_changes) AS multiple_lead_change_matches,
    COUNT(*) FILTER (WHERE has_red_card) AS red_card_matches,
    COUNT(*) FILTER (WHERE has_early_red_card) AS early_red_card_matches,
    COUNT(*) FILTER (WHERE has_decisive_penalty) AS decisive_penalty_wins,
    COUNT(*) FILTER (WHERE has_decisive_own_goal) AS decisive_own_goal_wins,
    COUNT(*) FILTER (WHERE has_var_intervention) AS var_matches,
    COUNT(*) FILTER (WHERE has_disallowed_goal) AS disallowed_goal_matches,
    COUNT(*) FILTER (WHERE goal_events_match_score) AS reliable_goal_sequences
FROM wins_taxonomy_match_level
WHERE is_target_eligible
GROUP BY scoreline_category
ORDER BY scoreline_category;


/*
3. Compare the overlapping narratives and circumstances descriptively.
   A match intentionally contributes to every flag that applies to it.
*/
SELECT
    f.flag_group,
    f.flag_name,
    COUNT(*) AS matches,
    ROUND(100.0 * COUNT(*) FILTER (WHERE w.winner_location = 'home')
          / NULLIF(COUNT(*), 0), 2) AS pct_home_wins,
    ROUND(AVG(w.goal_margin)::numeric, 2) AS avg_goal_margin,
    ROUND(AVG(w.winner_xg_margin)::numeric, 3) AS avg_winner_xg_margin,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY w.winner_xg_margin)
        AS median_winner_xg_margin,
    ROUND(AVG(w.winner_shot_margin)::numeric, 2) AS avg_winner_shot_margin,
    ROUND(AVG(w.winner_shots_on_goal_margin)::numeric, 2)
        AS avg_winner_shots_on_goal_margin,
    ROUND(AVG(w.winner_possession_margin)::numeric, 2)
        AS avg_winner_possession_margin,
    ROUND(AVG(w.winner_shot_conversion)::numeric, 3)
        AS avg_winner_shot_conversion,
    ROUND(AVG(w.winner_goals_minus_xg)::numeric, 3)
        AS avg_winner_goals_minus_xg
FROM wins_taxonomy_match_level w
CROSS JOIN LATERAL
(
    VALUES
        ('narrative', 'winner_scored_first', w.winner_scored_first),
        ('narrative', 'comeback_win', w.is_comeback_win),
        ('narrative', 'early_permanent_lead',
         w.is_early_lead_established_and_maintained),
        ('narrative', 'late_decisive_goal', w.has_late_decisive_goal),
        ('narrative', 'stoppage_time_decisive_goal',
         w.has_stoppage_time_decisive_goal),
        ('narrative', 'multiple_lead_changes', w.has_multiple_lead_changes),
        ('circumstance', 'red_card', w.has_red_card),
        ('circumstance', 'early_red_card', w.has_early_red_card),
        ('circumstance', 'decisive_penalty', w.has_decisive_penalty),
        ('circumstance', 'decisive_own_goal', w.has_decisive_own_goal),
        ('circumstance', 'var_intervention', w.has_var_intervention),
        ('circumstance', 'disallowed_goal', w.has_disallowed_goal)
) AS f(flag_group, flag_name, flag_value)
WHERE w.is_target_eligible
  AND w.outcome <> 'draw'
  AND f.flag_value IS TRUE
GROUP BY f.flag_group, f.flag_name
ORDER BY f.flag_group, f.flag_name;


/* 4. Scoreline statistics. Percentiles are safer than means for tails. */
SELECT
    scoreline_category,
    winner_location,
    COUNT(*) AS matches,
    ROUND(AVG(winner_xg_margin)::numeric, 3) AS avg_winner_xg_margin,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY winner_xg_margin)
        AS median_winner_xg_margin,
    ROUND(AVG(winner_shot_margin)::numeric, 2) AS avg_winner_shot_margin,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY winner_shot_margin)
        AS median_winner_shot_margin,
    ROUND(AVG(winner_shots_on_goal_margin)::numeric, 2)
        AS avg_winner_shots_on_goal_margin,
    ROUND(AVG(winner_possession_margin)::numeric, 2)
        AS avg_winner_possession_margin,
    ROUND(AVG(winner_shot_conversion)::numeric, 3)
        AS avg_winner_shot_conversion,
    ROUND(AVG(winner_goals_minus_xg)::numeric, 3)
        AS avg_winner_goals_minus_xg
FROM wins_taxonomy_match_level
WHERE is_target_eligible
  AND outcome <> 'draw'
GROUP BY scoreline_category, winner_location
ORDER BY scoreline_category, winner_location;


/* 5. Temporal stability and data availability. */
SELECT
    calendar_year,
    scoreline_category,
    COUNT(*) AS matches,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY calendar_year), 2)
        AS pct_matches_in_year,
    ROUND(100.0 * COUNT(*) FILTER (WHERE goal_events_match_score)
          / NULLIF(COUNT(*), 0), 2) AS pct_reliable_goal_sequences,
    ROUND(100.0 * COUNT(*) FILTER (WHERE has_team_stats_for_both_teams)
          / NULLIF(COUNT(*), 0), 2) AS pct_with_team_stats,
    ROUND(100.0 * COUNT(*) FILTER (WHERE has_xg_for_both_teams)
          / NULLIF(COUNT(*), 0), 2) AS pct_with_xg
FROM wins_taxonomy_match_level
WHERE is_target_eligible
GROUP BY calendar_year, scoreline_category
ORDER BY calendar_year, scoreline_category;


/* 6. Records that require a validity, completion, or data-quality review. */
SELECT
    fixture_id,
    date,
    league_season,
    home_team_id,
    away_team_id,
    home_goals,
    away_goals,
    status_elapsed,
    status_extra,
    status_short,
    status_long,
    is_normally_completed,
    is_administrative_result,
    is_not_completed,
    is_target_eligible,
    winner_flags_match_score,
    goal_events_match_score,
    has_event_data,
    has_team_stats_for_both_teams,
    has_xg_for_both_teams,
    suggested_review_decision
FROM wins_taxonomy_match_level
WHERE suggested_review_decision <> 'keep'
ORDER BY date, fixture_id;
