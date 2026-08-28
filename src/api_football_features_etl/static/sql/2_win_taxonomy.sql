/*
WIN / DRAW TAXONOMY
*/
DROP VIEW IF EXISTS wins_taxonomy_analysis;
DROP TABLE IF EXISTS transformed_prod_match_summary_win_taxonomy_features;
DROP TABLE IF EXISTS wins_taxonomy_h2h_features;
DROP TABLE IF EXISTS wins_taxonomy_venue_features;
DROP TABLE IF EXISTS wins_taxonomy_team_form_features;
DROP TABLE IF EXISTS wins_taxonomy_team_match;
DROP TABLE IF EXISTS wins_taxonomy_narratives;
DROP TABLE IF EXISTS wins_taxonomy_goal_sequence;
DROP TABLE IF EXISTS wins_taxonomy_events;
DROP TABLE IF EXISTS wins_taxonomy_statistics;
DROP TABLE IF EXISTS wins_taxonomy_matches;
DROP TABLE IF EXISTS wins_taxonomy_match_level;


/*
1. MATCHES: target, scoreline, teams, and fixture validity.

FT, AET, and PEN are treated as completed. AWD and WO are administrative
results. Other statuses are not eligible modelling targets.
*/
CREATE TEMP TABLE wins_taxonomy_matches AS
SELECT
    m.fixture_id,
    m.date,
    EXTRACT(YEAR FROM m.date)::integer AS calendar_year,
    m.league_id,
    m.league_season,
    m.league_round,
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
        WHEN m.home_goals = 0 AND m.away_goals = 0 THEN 'goalless_draw'
        WHEN m.home_goals = 1 AND m.away_goals = 1 THEN 'one_one_draw'
        WHEN m.home_goals = m.away_goals THEN 'high_scoring_draw'
        WHEN ABS(m.home_goals - m.away_goals) = 1 THEN 'one_goal_win'
        WHEN ABS(m.home_goals - m.away_goals) = 2 THEN 'two_goal_win'
        WHEN ABS(m.home_goals - m.away_goals) >= 3 THEN 'three_plus_goal_win'
    END AS scoreline_category,
    /* Validate that the provider's winner flags agree with the final score. */
    CASE
        WHEN m.home_goals IS NULL OR m.away_goals IS NULL THEN FALSE
        WHEN m.home_goals > m.away_goals
            THEN m.home_winner IS TRUE AND m.away_winner IS FALSE
        WHEN m.home_goals < m.away_goals
            THEN m.home_winner IS FALSE AND m.away_winner IS TRUE
        ELSE COALESCE(m.home_winner, FALSE) IS FALSE
             AND COALESCE(m.away_winner, FALSE) IS FALSE
    END AS winner_flags_match_score,
    COALESCE(UPPER(TRIM(m.status_short)) IN ('FT', 'AET', 'PEN'), FALSE)
        AS is_normally_completed,
    COALESCE(UPPER(TRIM(m.status_short)) IN ('AWD', 'WO'), FALSE)
        AS is_administrative_result,
    COALESCE(
        UPPER(TRIM(m.status_short)) NOT IN ('FT', 'AET', 'PEN', 'AWD', 'WO'),
        TRUE
    )
        AS is_not_completed,
    (
        COALESCE(UPPER(TRIM(m.status_short)) IN ('FT', 'AET', 'PEN'), FALSE)
        AND m.home_goals IS NOT NULL
        AND m.away_goals IS NOT NULL
        AND CASE
                WHEN m.home_goals > m.away_goals
                    THEN m.home_winner IS TRUE AND m.away_winner IS FALSE
                WHEN m.home_goals < m.away_goals
                    THEN m.home_winner IS FALSE AND m.away_winner IS TRUE
                ELSE COALESCE(m.home_winner, FALSE) IS FALSE
                     AND COALESCE(m.away_winner, FALSE) IS FALSE
            END
    ) AS is_target_eligible
FROM prod_match_summary m
WHERE m.league_id = 128 AND league_season <= 2024;


/*
2. STATISTICS: raw home/away values and winner-minus-loser measures.
*/
CREATE TEMP TABLE wins_taxonomy_statistics AS
WITH team_stats AS
(
    SELECT
        s.fixture_id,
        s.team_id,
        MAX(s.stat_value) FILTER
            (WHERE REPLACE(TRIM(LOWER(s.stat_type)), ' ', '_') = 'shots_on_goal')
            AS shots_on_goal,
        MAX(s.stat_value) FILTER
            (WHERE REPLACE(TRIM(LOWER(s.stat_type)), ' ', '_') = 'total_shots')
            AS total_shots,
        MAX(s.stat_value) FILTER
            (WHERE REPLACE(TRIM(LOWER(s.stat_type)), ' ', '_') = 'ball_possession')
            AS ball_possession,
        MAX(s.stat_value) FILTER
            (WHERE REPLACE(TRIM(LOWER(s.stat_type)), ' ', '_') = 'red_cards')
            AS red_cards,
        MAX(s.stat_value) FILTER
            (WHERE REPLACE(TRIM(LOWER(s.stat_type)), ' ', '_') = 'yellow_cards')
            AS yellow_cards,
        MAX(s.stat_value) FILTER
            (WHERE REPLACE(TRIM(LOWER(s.stat_type)), ' ', '_') = 'goalkeeper_saves')
            AS goalkeeper_saves,
        MAX(s.stat_value) FILTER
            (WHERE REPLACE(TRIM(LOWER(s.stat_type)), ' ', '_') = 'expected_goals')
            AS expected_goals,
        COUNT(DISTINCT REPLACE(TRIM(LOWER(s.stat_type)), ' ', '_'))
            AS supplied_stat_count
    FROM prod_match_team_stats s
    INNER JOIN wins_taxonomy_matches m USING (fixture_id)
    GROUP BY s.fixture_id, s.team_id
)
SELECT
    m.fixture_id,
    (hs.supplied_stat_count > 0 AND aws.supplied_stat_count > 0)
        AS has_team_stats_for_both_teams,
    (hs.expected_goals IS NOT NULL AND aws.expected_goals IS NOT NULL)
        AS has_xg_for_both_teams,
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
    CASE WHEN m.winner_location = 'home'
         THEN hs.expected_goals - aws.expected_goals
         WHEN m.winner_location = 'away'
         THEN aws.expected_goals - hs.expected_goals END AS winner_xg_margin,
    CASE WHEN m.winner_location = 'home'
         THEN hs.total_shots - aws.total_shots
         WHEN m.winner_location = 'away'
         THEN aws.total_shots - hs.total_shots END AS winner_shot_margin,
    CASE WHEN m.winner_location = 'home'
         THEN hs.shots_on_goal - aws.shots_on_goal
         WHEN m.winner_location = 'away'
         THEN aws.shots_on_goal - hs.shots_on_goal END
        AS winner_shots_on_goal_margin,
    CASE WHEN m.winner_location = 'home'
         THEN hs.ball_possession - aws.ball_possession
         WHEN m.winner_location = 'away'
         THEN aws.ball_possession - hs.ball_possession END
        AS winner_possession_margin,
    CASE WHEN m.winner_location = 'home' AND hs.total_shots <> 0
         THEN m.home_goals::numeric / hs.total_shots
         WHEN m.winner_location = 'away' AND aws.total_shots <> 0
         THEN m.away_goals::numeric / aws.total_shots END
        AS winner_shot_conversion,
    CASE WHEN m.winner_location = 'home'
         THEN m.home_goals - hs.expected_goals
         WHEN m.winner_location = 'away'
         THEN m.away_goals - aws.expected_goals END AS winner_goals_minus_xg
FROM wins_taxonomy_matches m
LEFT JOIN team_stats hs
    ON hs.fixture_id = m.fixture_id AND hs.team_id = m.home_team_id
LEFT JOIN team_stats aws
    ON aws.fixture_id = m.fixture_id AND aws.team_id = m.away_team_id;


/* 3. EVENTS: normalized raw events. This table is directly inspectable. */
CREATE TEMP TABLE wins_taxonomy_events AS
SELECT
    e.fixture_id,
    e.team_id,
    e.minute AS event_minute,
    COALESCE(e.extra, 0) AS event_extra,
    e.minute + COALESCE(e.extra, 0) AS display_minute,
    REPLACE(TRIM(LOWER(e.event_type)), ' ', '_') AS event_type,
    REPLACE(TRIM(LOWER(e.detail)), ' ', '_') AS event_detail
FROM prod_match_events e
INNER JOIN wins_taxonomy_matches m USING (fixture_id);


/*
4. GOAL SEQUENCE: one row per valid goal, including score and leader states.
*/
CREATE TEMP TABLE wins_taxonomy_goal_sequence AS
WITH valid_goals AS
(
    SELECT
        e.*,
        ROW_NUMBER() OVER
        (
            PARTITION BY e.fixture_id
            ORDER BY e.event_minute, e.event_extra, e.team_id, e.event_detail
        ) AS goal_number
    FROM wins_taxonomy_events e
    WHERE e.event_type = 'goal'
      AND e.event_detail IN ('normal_goal', 'penalty', 'own_goal')
),
scores_before_goal AS
(
    SELECT
        g.*,
        m.home_team_id,
        m.away_team_id,
        m.winner_team_id,
        m.loser_team_id,
        -- copy previous score for each when a goal is scored
        COALESCE(SUM((g.team_id = m.home_team_id)::integer) OVER
        (
            PARTITION BY g.fixture_id ORDER BY g.goal_number
            ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
        ), 0) AS home_score_before,
        COALESCE(SUM((g.team_id = m.away_team_id)::integer) OVER
        (
            PARTITION BY g.fixture_id ORDER BY g.goal_number
            ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
        ), 0) AS away_score_before
    FROM valid_goals g
    INNER JOIN wins_taxonomy_matches m USING (fixture_id)
)
SELECT
    g.*,
    -- for either team home or away score, the current score (or after) is the previous score plus 1 if the team scored (which is what the = is doing)
    g.home_score_before + (g.team_id = g.home_team_id)::integer
        AS home_score_after,
    g.away_score_before + (g.team_id = g.away_team_id)::integer
        AS away_score_after,
    -- leader before is the team with the higher score before the goal, or null if tied
    CASE
        WHEN g.home_score_before > g.away_score_before THEN g.home_team_id
        WHEN g.away_score_before > g.home_score_before THEN g.away_team_id
    END AS leader_before,
    -- leader after is the team with the higher score after the goal, or null if tied
    CASE
        WHEN g.home_score_before + (g.team_id = g.home_team_id)::integer
           > g.away_score_before + (g.team_id = g.away_team_id)::integer
            THEN g.home_team_id
        WHEN g.away_score_before + (g.team_id = g.away_team_id)::integer
           > g.home_score_before + (g.team_id = g.home_team_id)::integer
            THEN g.away_team_id
    END AS leader_after
FROM scores_before_goal g;


/*
5. NARRATIVES: reconciliation, narrative flags, circumstances, and review.
*/
CREATE TEMP TABLE wins_taxonomy_narratives AS
WITH goal_reconciliation AS
(
    SELECT
        m.fixture_id,
        COUNT(g.goal_number) AS recorded_goal_count,
        COUNT(g.goal_number) FILTER (WHERE g.team_id = m.home_team_id)
            AS recorded_home_goals,
        COUNT(g.goal_number) FILTER (WHERE g.team_id = m.away_team_id)
            AS recorded_away_goals,
        COUNT(g.goal_number) FILTER (WHERE g.team_id = m.home_team_id)
                = m.home_goals
        AND COUNT(g.goal_number) FILTER (WHERE g.team_id = m.away_team_id)
                = m.away_goals AS goal_events_match_score -- check how many do not match the final score
    FROM wins_taxonomy_matches m
    LEFT JOIN wins_taxonomy_goal_sequence g USING (fixture_id)
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
                WHEN m.winner_location = 'home'
                    THEN g.home_score_after < g.away_score_after -- if home wins but it was behind at any point, then it trailed
                WHEN m.winner_location = 'away'
                    THEN g.away_score_after < g.home_score_after -- if away wins but it was behind at any point, then it trailed
                ELSE FALSE
            END
        ) AS winner_trailed,
        COUNT(*) FILTER
        (
            WHERE g.leader_after IS NOT NULL
              AND g.leader_after IS DISTINCT FROM g.leader_before -- count the number of times the leader changed, excluding score updates that did not change the leader (e.g., 1-0 to 2-0 or 2-0 to 2-1)
        ) AS lead_spell_count,
        MAX(g.goal_number) FILTER
        (
            WHERE g.team_id = m.winner_team_id
              AND ((m.winner_location = 'home'
                    AND g.home_score_before <= g.away_score_before)
                   OR (m.winner_location = 'away'
                       AND g.away_score_before <= g.home_score_before))
        ) AS decisive_goal_number -- yields the last goal number that put the eventual winner ahead of the loser, or null if the match was a draw
    FROM wins_taxonomy_matches m
    LEFT JOIN wins_taxonomy_goal_sequence g USING (fixture_id)
    GROUP BY m.fixture_id
),
narrative_details AS
(
    SELECT
        n.*,
        g.display_minute AS decisive_goal_minute,
        g.event_minute AS decisive_goal_elapsed,
        g.event_extra AS decisive_goal_extra,
        g.event_detail AS decisive_goal_detail
    FROM narrative_raw n
    LEFT JOIN wins_taxonomy_goal_sequence g
        ON g.fixture_id = n.fixture_id
       AND g.goal_number = n.decisive_goal_number
),
event_circumstances AS
(
    SELECT
        m.fixture_id,
        COUNT(e.fixture_id) AS event_count,
        BOOL_OR(e.event_type = 'card' AND e.event_detail = 'red_card')
            AS has_red_card,
        BOOL_OR(e.event_type = 'card' AND e.event_detail = 'red_card'
                AND e.display_minute <= 30) AS has_early_red_card,
        BOOL_OR(e.event_type = 'var'
                OR e.event_detail IN ('card_reviewed', 'card_upgrade',
                                      'goal_confirmed', 'penalty_confirmed'))
            AS has_var_intervention,
        BOOL_OR(e.event_detail IN ('goal_cancelled', 'goal_disallowed',
                                   'goal_disallowed_foul',
                                   'goal_disallowed_handball',
                                   'goal_disallowed_offside'))
            AS has_disallowed_goal
    FROM wins_taxonomy_matches m
    LEFT JOIN wins_taxonomy_events e USING (fixture_id)
    GROUP BY m.fixture_id
)
SELECT
    m.fixture_id,
    r.recorded_goal_count,
    r.recorded_home_goals,
    r.recorded_away_goals,
    r.goal_events_match_score,
    (e.event_count > 0) AS has_event_data,
    CASE WHEN r.goal_events_match_score
         THEN n.first_scorer_team_id = m.winner_team_id END
        AS winner_scored_first,
    CASE WHEN r.goal_events_match_score
         THEN n.first_scorer_team_id = m.loser_team_id END
        AS loser_scored_first,
    CASE WHEN r.goal_events_match_score AND m.outcome <> 'draw'
         THEN n.winner_trailed END AS is_comeback_win,
    CASE WHEN r.goal_events_match_score AND m.outcome <> 'draw'
         THEN n.decisive_goal_minute <= 30 END
        AS is_early_lead_established_and_maintained,
    CASE WHEN r.goal_events_match_score AND m.outcome <> 'draw'
         THEN n.decisive_goal_minute >= 76 END AS has_late_decisive_goal,
    CASE WHEN r.goal_events_match_score AND m.outcome <> 'draw'
         THEN n.decisive_goal_elapsed > 90
              OR (n.decisive_goal_elapsed >= 90 AND n.decisive_goal_extra > 0)
         END AS has_stoppage_time_decisive_goal,
    CASE WHEN r.goal_events_match_score
         THEN GREATEST(n.lead_spell_count - 1, 0) END AS lead_change_count,
    CASE WHEN r.goal_events_match_score
         THEN GREATEST(n.lead_spell_count - 1, 0) >= 2 END
        AS has_multiple_lead_changes,
    n.decisive_goal_minute,
    e.has_red_card,
    e.has_early_red_card,
    e.has_var_intervention,
    e.has_disallowed_goal,
    CASE WHEN r.goal_events_match_score AND m.outcome <> 'draw'
         THEN n.decisive_goal_detail = 'penalty' END AS has_decisive_penalty,
    CASE WHEN r.goal_events_match_score AND m.outcome <> 'draw'
         THEN n.decisive_goal_detail = 'own_goal' END AS has_decisive_own_goal,
    CASE
        WHEN m.home_goals IS NULL OR m.away_goals IS NULL
            THEN 'exclude_invalid_target'
        WHEN m.is_administrative_result THEN 'exclude_administrative_result'
        WHEN m.is_not_completed THEN 'exclude_not_completed'
        WHEN NOT m.winner_flags_match_score THEN 'review_target_inconsistency'
        WHEN NOT r.goal_events_match_score THEN 'keep_result_review_event_data'
        ELSE 'keep'
    END AS suggested_review_decision
FROM wins_taxonomy_matches m
LEFT JOIN goal_reconciliation r USING (fixture_id)
LEFT JOIN narrative_details n USING (fixture_id)
LEFT JOIN event_circumstances e USING (fixture_id);

