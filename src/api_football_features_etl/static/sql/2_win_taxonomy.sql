/*
WIN / DRAW TAXONOMY
*/
DROP VIEW IF EXISTS wins_taxonomy_analysis;
DROP TABLE IF EXISTS transformed_prod_match_summary_win_taxonomy_features;
DROP TABLE IF EXISTS wins_taxonomy_h2h_features;
DROP TABLE IF EXISTS wins_taxonomy_venue_features;
DROP TABLE IF EXISTS wins_taxonomy_team_form_features;
DROP TABLE IF EXISTS wins_taxonomy_team_match;
DROP TABLE IF EXISTS wins_taxonomy_match_level;
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


/*
6. MATCH-LEVEL TAXONOMY
-----------------------
One retrospective row per eligible match. This is an intermediate source for
historical windows and must not be used as same-match model input.
*/
/* UNLOGGED so downstream EDA scripts can reuse it from another DB session. */
CREATE UNLOGGED TABLE wins_taxonomy_match_level AS
SELECT
    m.fixture_id,
    m.date,
    m.league_id,
    m.league_season,
    m.league_round,
    m.venue_id,
    m.venue_name,
    m.home_team_id,
    m.away_team_id,
    m.home_goals,
    m.away_goals,
    m.outcome,
    m.winner_team_id,
    m.loser_team_id,
    m.scoreline_category,
    n.goal_events_match_score,
    n.is_comeback_win,
    n.is_early_lead_established_and_maintained,
    n.has_late_decisive_goal,
    n.has_stoppage_time_decisive_goal,
    n.has_multiple_lead_changes,
    n.has_red_card,
    n.has_early_red_card,
    n.has_var_intervention,
    n.has_disallowed_goal,
    n.has_decisive_penalty,
    n.has_decisive_own_goal,
    s.home_shots_on_goal,
    s.away_shots_on_goal,
    s.home_total_shots,
    s.away_total_shots,
    s.home_ball_possession,
    s.away_ball_possession,
    s.home_red_cards,
    s.away_red_cards,
    s.home_yellow_cards,
    s.away_yellow_cards,
    s.home_expected_goals,
    s.away_expected_goals
FROM wins_taxonomy_matches m
LEFT JOIN wins_taxonomy_narratives n USING (fixture_id)
LEFT JOIN wins_taxonomy_statistics s USING (fixture_id)
WHERE m.is_target_eligible;


/* 7. TEAM PERSPECTIVE: two rows per match, one for each team. */
/* UNLOGGED so downstream EDA scripts can reuse it from another DB session. */
CREATE UNLOGGED TABLE wins_taxonomy_team_match AS
WITH team_rows AS
(
    SELECT
        m.*,
        home_team_id AS team_id,
        away_team_id AS opponent_team_id,
        TRUE AS is_home,
        home_goals AS goals_for,
        away_goals AS goals_against,
        home_shots_on_goal AS shots_on_goal_for,
        away_shots_on_goal AS shots_on_goal_against,
        home_total_shots AS total_shots_for,
        away_total_shots AS total_shots_against,
        home_ball_possession AS possession,
        home_red_cards AS red_cards,
        home_yellow_cards AS yellow_cards,
        home_expected_goals AS xg_for,
        away_expected_goals AS xg_against
    FROM wins_taxonomy_match_level m

    UNION ALL

    SELECT
        m.*,
        away_team_id,
        home_team_id,
        FALSE,
        away_goals,
        home_goals,
        away_shots_on_goal,
        home_shots_on_goal,
        away_total_shots,
        home_total_shots,
        away_ball_possession,
        away_red_cards,
        away_yellow_cards,
        away_expected_goals,
        home_expected_goals
    FROM wins_taxonomy_match_level m
)
SELECT
    fixture_id,
    date,
    league_id,
    league_season,
    team_id,
    opponent_team_id,
    is_home,
    goals_for,
    goals_against,
    goals_for - goals_against AS goal_difference,
    shots_on_goal_for,
    shots_on_goal_against,
    total_shots_for,
    total_shots_against,
    possession,
    red_cards,
    yellow_cards,
    xg_for,
    xg_against,
    xg_for - xg_against AS xg_difference,
    /* winner/loser ids are NULL for draws. COALESCE ensures draws contribute
       won = 0 and lost = 0 instead of disappearing from rolling averages. */
    COALESCE(team_id = winner_team_id, FALSE)::integer AS won,
    COALESCE(team_id = loser_team_id, FALSE)::integer AS lost,
    (outcome = 'draw')::integer AS drew,
    (scoreline_category = 'one_goal_win')::integer AS one_goal_match,
    goal_events_match_score,
    CASE WHEN goal_events_match_score THEN
        (team_id = winner_team_id AND is_comeback_win)::integer END
        AS comeback_win,
    CASE WHEN goal_events_match_score THEN
        (team_id = loser_team_id AND is_comeback_win)::integer END
        AS comeback_loss,
    CASE WHEN goal_events_match_score THEN
        (team_id = winner_team_id
         AND is_early_lead_established_and_maintained)::integer END
        AS early_permanent_lead_win,
    CASE WHEN goal_events_match_score THEN
        (team_id = winner_team_id AND has_late_decisive_goal)::integer END
        AS late_decisive_win,
    CASE WHEN goal_events_match_score THEN
        (team_id = loser_team_id AND has_late_decisive_goal)::integer END
        AS late_decisive_loss,
    CASE WHEN goal_events_match_score THEN
        (team_id = winner_team_id
         AND has_stoppage_time_decisive_goal)::integer END
        AS stoppage_time_win,
    CASE WHEN goal_events_match_score THEN
        has_multiple_lead_changes::integer END AS multiple_lead_changes,
    has_red_card::integer AS match_had_red_card,
    has_early_red_card::integer AS match_had_early_red_card,
    has_var_intervention::integer AS match_had_var,
    has_disallowed_goal::integer AS match_had_disallowed_goal,
    CASE WHEN goal_events_match_score THEN
        (team_id = winner_team_id AND has_decisive_penalty)::integer END
        AS decisive_penalty_win,
    CASE WHEN goal_events_match_score THEN
        (team_id = winner_team_id AND has_decisive_own_goal)::integer END
        AS decisive_own_goal_win
FROM team_rows;

CREATE INDEX IF NOT EXISTS wins_taxonomy_team_match_team_date_idx
    ON wins_taxonomy_team_match (team_id, date, fixture_id);

CREATE INDEX IF NOT EXISTS wins_taxonomy_team_match_fixture_team_idx
    ON wins_taxonomy_team_match (fixture_id, team_id);


/*
8. OVERALL TEAM HISTORY
-----------------------
*/
CREATE TEMP TABLE wins_taxonomy_team_form_features AS
SELECT
    fixture_id,
    team_id,
    COUNT(*) OVER w5 AS matches_last_5,
    AVG(won) OVER w5 AS win_rate_last_5,
    AVG(drew) OVER w5 AS draw_rate_last_5,
    AVG(goals_for) OVER w5 AS goals_for_avg_last_5,
    AVG(goals_against) OVER w5 AS goals_against_avg_last_5,
    AVG(goal_difference) OVER w5 AS goal_difference_avg_last_5,
    AVG(shots_on_goal_for) OVER w5 AS shots_on_goal_for_avg_last_5,
    AVG(shots_on_goal_against) OVER w5 AS shots_on_goal_against_avg_last_5,
    AVG(total_shots_for) OVER w5 AS total_shots_for_avg_last_5,
    AVG(possession) OVER w5 AS possession_avg_last_5,
    AVG(red_cards) OVER w5 AS red_cards_avg_last_5,
    AVG(yellow_cards) OVER w5 AS yellow_cards_avg_last_5,
    AVG(xg_for) OVER w5 AS xg_for_avg_last_5,
    AVG(xg_against) OVER w5 AS xg_against_avg_last_5,
    AVG(xg_difference) OVER w5 AS xg_difference_avg_last_5,
    AVG(one_goal_match) OVER w5 AS one_goal_match_rate_last_5,
    COUNT(*) FILTER (WHERE goal_events_match_score) OVER w5 AS reliable_narrative_matches_last_5,
    AVG(comeback_win) OVER w5 AS comeback_win_rate_last_5,
    AVG(comeback_loss) OVER w5 AS comeback_loss_rate_last_5,
    AVG(early_permanent_lead_win) OVER w5 AS early_lead_win_rate_last_5,
    AVG(late_decisive_win) OVER w5 AS late_win_rate_last_5,
    AVG(late_decisive_loss) OVER w5 AS late_loss_rate_last_5,
    AVG(stoppage_time_win) OVER w5 AS stoppage_win_rate_last_5,
    AVG(multiple_lead_changes) OVER w5 AS lead_change_rate_last_5,
    AVG(match_had_red_card) OVER w5 AS red_card_match_rate_last_5,
    AVG(match_had_early_red_card) OVER w5 AS early_red_card_rate_last_5,
    AVG(match_had_var) OVER w5 AS var_match_rate_last_5,
    AVG(match_had_disallowed_goal) OVER w5 AS disallowed_goal_rate_last_5,
    AVG(decisive_penalty_win) OVER w5 AS decisive_penalty_win_rate_last_5,
    AVG(decisive_own_goal_win) OVER w5 AS decisive_own_goal_win_rate_last_5,
    COUNT(*) OVER w10 AS matches_last_10,
    AVG(won) OVER w10 AS win_rate_last_10,
    AVG(drew) OVER w10 AS draw_rate_last_10,
    AVG(goals_for) OVER w10 AS goals_for_avg_last_10,
    AVG(goals_against) OVER w10 AS goals_against_avg_last_10,
    AVG(goal_difference) OVER w10 AS goal_difference_avg_last_10,
    AVG(xg_difference) OVER w10 AS xg_difference_avg_last_10,
    AVG(comeback_win) OVER w10 AS comeback_win_rate_last_10,
    AVG(early_permanent_lead_win) OVER w10 AS early_lead_win_rate_last_10,
    AVG(late_decisive_win) OVER w10 AS late_win_rate_last_10,
    AVG(late_decisive_loss) OVER w10 AS late_loss_rate_last_10,
    AVG(match_had_red_card) OVER w10 AS red_card_match_rate_last_10
FROM wins_taxonomy_team_match
WINDOW
    w5 AS (
        PARTITION BY league_id, team_id
        ORDER BY date, fixture_id
        ROWS BETWEEN 5 PRECEDING AND 1 PRECEDING
    ),
    w10 AS (
        PARTITION BY league_id, team_id
        ORDER BY date, fixture_id
        ROWS BETWEEN 10 PRECEDING AND 1 PRECEDING
    );


/* 9. LOCATION-SPECIFIC HISTORY: home form and away form remain separate. */
CREATE TEMP TABLE wins_taxonomy_venue_features AS
SELECT
    fixture_id,
    team_id,
    COUNT(*) OVER w AS venue_matches_last_5,
    AVG(won) OVER w AS venue_win_rate_last_5,
    AVG(drew) OVER w AS venue_draw_rate_last_5,
    AVG(goals_for) OVER w AS venue_goals_for_avg_last_5,
    AVG(goals_against) OVER w AS venue_goals_against_avg_last_5,
    AVG(goal_difference) OVER w AS venue_goal_difference_avg_last_5,
    AVG(xg_difference) OVER w AS venue_xg_difference_avg_last_5,
    AVG(comeback_win) OVER w AS venue_comeback_win_rate_last_5,
    AVG(late_decisive_win) OVER w AS venue_late_win_rate_last_5,
    AVG(late_decisive_loss) OVER w AS venue_late_loss_rate_last_5
FROM wins_taxonomy_team_match
WINDOW w AS (
    PARTITION BY league_id, team_id, is_home
    ORDER BY date, fixture_id
    ROWS BETWEEN 5 PRECEDING AND 1 PRECEDING
);


/* 10. HEAD-TO-HEAD HISTORY from the current team's perspective. */
CREATE TEMP TABLE wins_taxonomy_h2h_features AS
SELECT
    fixture_id,
    team_id,
    COUNT(*) OVER w AS h2h_matches_last_5,
    AVG(won) OVER w AS h2h_win_rate_last_5,
    AVG(drew) OVER w AS h2h_draw_rate_last_5,
    AVG(goals_for) OVER w AS h2h_goals_for_avg_last_5,
    AVG(goals_against) OVER w AS h2h_goals_against_avg_last_5,
    AVG(goal_difference) OVER w AS h2h_goal_difference_avg_last_5,
    AVG(one_goal_match) OVER w AS h2h_one_goal_match_rate_last_5,
    AVG(comeback_win) OVER w AS h2h_comeback_win_rate_last_5,
    AVG(late_decisive_win) OVER w AS h2h_late_win_rate_last_5,
    AVG(late_decisive_loss) OVER w AS h2h_late_loss_rate_last_5
FROM wins_taxonomy_team_match
WINDOW w AS (
    PARTITION BY league_id, team_id, opponent_team_id
    ORDER BY date, fixture_id
    ROWS BETWEEN 5 PRECEDING AND 1 PRECEDING
);


/*
11. FINAL PREDICTION TABLE
--------------------------
*/
CREATE TABLE transformed_prod_match_summary_win_taxonomy_features AS
WITH match_targets AS
(
    SELECT
        fixture_id,
        date,
        league_id,
        league_season,
        league_round,
        venue_id,
        venue_name,
        home_team_id,
        away_team_id,
        CASE outcome
            WHEN 'home_win' THEN 1
            WHEN 'away_win' THEN 2
            WHEN 'draw' THEN 0
        END AS target
    FROM wins_taxonomy_matches
    WHERE is_target_eligible
),
home_features AS
(
    SELECT f.*, v.venue_matches_last_5, v.venue_win_rate_last_5,
        v.venue_draw_rate_last_5, v.venue_goals_for_avg_last_5,
        v.venue_goals_against_avg_last_5,
        v.venue_goal_difference_avg_last_5, v.venue_xg_difference_avg_last_5,
        v.venue_comeback_win_rate_last_5, v.venue_late_win_rate_last_5,
        v.venue_late_loss_rate_last_5,
        h.h2h_matches_last_5, h.h2h_win_rate_last_5,
        h.h2h_draw_rate_last_5, h.h2h_goals_for_avg_last_5,
        h.h2h_goals_against_avg_last_5, h.h2h_goal_difference_avg_last_5,
        h.h2h_one_goal_match_rate_last_5, h.h2h_comeback_win_rate_last_5,
        h.h2h_late_win_rate_last_5, h.h2h_late_loss_rate_last_5
    FROM wins_taxonomy_team_form_features f
    LEFT JOIN wins_taxonomy_venue_features v USING (fixture_id, team_id)
    LEFT JOIN wins_taxonomy_h2h_features h USING (fixture_id, team_id)
),
away_features AS
(
    SELECT * FROM home_features
)
SELECT
    m.*
    ,hf.matches_last_5 AS home_matches_last_5
    ,hf.win_rate_last_5 AS home_win_rate_last_5
    ,hf.draw_rate_last_5 AS home_draw_rate_last_5
    ,hf.goals_for_avg_last_5 AS home_goals_for_avg_last_5
    ,hf.goals_against_avg_last_5 AS home_goals_against_avg_last_5
    ,hf.goal_difference_avg_last_5 AS home_goal_difference_avg_last_5
    ,hf.shots_on_goal_for_avg_last_5 AS home_shots_on_goal_for_avg_last_5
    ,hf.shots_on_goal_against_avg_last_5 AS home_shots_on_goal_against_avg_last_5
    ,hf.total_shots_for_avg_last_5 AS home_total_shots_for_avg_last_5
    ,hf.possession_avg_last_5 AS home_possession_avg_last_5
    ,hf.red_cards_avg_last_5 AS home_red_cards_avg_last_5
    ,hf.yellow_cards_avg_last_5 AS home_yellow_cards_avg_last_5
    ,hf.xg_for_avg_last_5 AS home_xg_for_avg_last_5
    ,hf.xg_against_avg_last_5 AS home_xg_against_avg_last_5
    ,hf.xg_difference_avg_last_5 AS home_xg_difference_avg_last_5
    ,hf.one_goal_match_rate_last_5 AS home_one_goal_match_rate_last_5
    ,hf.reliable_narrative_matches_last_5 AS home_reliable_narrative_matches_last_5
    ,hf.comeback_win_rate_last_5 AS home_comeback_win_rate_last_5
    ,hf.comeback_loss_rate_last_5 AS home_comeback_loss_rate_last_5
    ,hf.early_lead_win_rate_last_5 AS home_early_lead_win_rate_last_5
    ,hf.late_win_rate_last_5 AS home_late_win_rate_last_5
    ,hf.late_loss_rate_last_5 AS home_late_loss_rate_last_5
    ,hf.stoppage_win_rate_last_5 AS home_stoppage_win_rate_last_5
    ,hf.lead_change_rate_last_5 AS home_lead_change_rate_last_5
    ,hf.red_card_match_rate_last_5 AS home_red_card_match_rate_last_5
    ,hf.early_red_card_rate_last_5 AS home_early_red_card_rate_last_5
    ,hf.var_match_rate_last_5 AS home_var_match_rate_last_5
    ,hf.disallowed_goal_rate_last_5 AS home_disallowed_goal_rate_last_5
    ,hf.decisive_penalty_win_rate_last_5 AS home_decisive_penalty_win_rate_last_5
    ,hf.decisive_own_goal_win_rate_last_5 AS home_decisive_own_goal_win_rate_last_5
    ,hf.matches_last_10 AS home_matches_last_10
    ,hf.win_rate_last_10 AS home_win_rate_last_10
    ,hf.draw_rate_last_10 AS home_draw_rate_last_10
    ,hf.goals_for_avg_last_10 AS home_goals_for_avg_last_10
    ,hf.goals_against_avg_last_10 AS home_goals_against_avg_last_10
    ,hf.goal_difference_avg_last_10 AS home_goal_difference_avg_last_10
    ,hf.xg_difference_avg_last_10 AS home_xg_difference_avg_last_10
    ,hf.comeback_win_rate_last_10 AS home_comeback_win_rate_last_10
    ,hf.early_lead_win_rate_last_10 AS home_early_lead_win_rate_last_10
    ,hf.late_win_rate_last_10 AS home_late_win_rate_last_10
    ,hf.late_loss_rate_last_10 AS home_late_loss_rate_last_10
    ,hf.red_card_match_rate_last_10 AS home_red_card_match_rate_last_10
    ,hf.venue_matches_last_5 AS home_venue_matches_last_5
    ,hf.venue_win_rate_last_5 AS home_venue_win_rate_last_5
    ,hf.venue_draw_rate_last_5 AS home_venue_draw_rate_last_5
    ,hf.venue_goals_for_avg_last_5 AS home_venue_goals_for_avg_last_5
    ,hf.venue_goals_against_avg_last_5 AS home_venue_goals_against_avg_last_5
    ,hf.venue_goal_difference_avg_last_5 AS home_venue_goal_difference_avg_last_5
    ,hf.venue_xg_difference_avg_last_5 AS home_venue_xg_difference_avg_last_5
    ,hf.venue_comeback_win_rate_last_5 AS home_venue_comeback_win_rate_last_5
    ,hf.venue_late_win_rate_last_5 AS home_venue_late_win_rate_last_5
    ,hf.venue_late_loss_rate_last_5 AS home_venue_late_loss_rate_last_5
    ,hf.h2h_matches_last_5 AS home_h2h_matches_last_5
    ,hf.h2h_win_rate_last_5 AS home_h2h_win_rate_last_5
    ,hf.h2h_draw_rate_last_5 AS home_h2h_draw_rate_last_5
    ,hf.h2h_goals_for_avg_last_5 AS home_h2h_goals_for_avg_last_5
    ,hf.h2h_goals_against_avg_last_5 AS home_h2h_goals_against_avg_last_5
    ,hf.h2h_goal_difference_avg_last_5 AS home_h2h_goal_difference_avg_last_5
    ,hf.h2h_one_goal_match_rate_last_5 AS home_h2h_one_goal_match_rate_last_5
    ,hf.h2h_comeback_win_rate_last_5 AS home_h2h_comeback_win_rate_last_5
    ,hf.h2h_late_win_rate_last_5 AS home_h2h_late_win_rate_last_5
    ,hf.h2h_late_loss_rate_last_5 AS home_h2h_late_loss_rate_last_5

    ,af.matches_last_5 AS away_matches_last_5
    ,af.win_rate_last_5 AS away_win_rate_last_5
    ,af.draw_rate_last_5 AS away_draw_rate_last_5
    ,af.goals_for_avg_last_5 AS away_goals_for_avg_last_5
    ,af.goals_against_avg_last_5 AS away_goals_against_avg_last_5
    ,af.goal_difference_avg_last_5 AS away_goal_difference_avg_last_5
    ,af.shots_on_goal_for_avg_last_5 AS away_shots_on_goal_for_avg_last_5
    ,af.shots_on_goal_against_avg_last_5 AS away_shots_on_goal_against_avg_last_5
    ,af.total_shots_for_avg_last_5 AS away_total_shots_for_avg_last_5
    ,af.possession_avg_last_5 AS away_possession_avg_last_5
    ,af.red_cards_avg_last_5 AS away_red_cards_avg_last_5
    ,af.yellow_cards_avg_last_5 AS away_yellow_cards_avg_last_5
    ,af.xg_for_avg_last_5 AS away_xg_for_avg_last_5
    ,af.xg_against_avg_last_5 AS away_xg_against_avg_last_5
    ,af.xg_difference_avg_last_5 AS away_xg_difference_avg_last_5
    ,af.one_goal_match_rate_last_5 AS away_one_goal_match_rate_last_5
    ,af.reliable_narrative_matches_last_5 AS away_reliable_narrative_matches_last_5
    ,af.comeback_win_rate_last_5 AS away_comeback_win_rate_last_5
    ,af.comeback_loss_rate_last_5 AS away_comeback_loss_rate_last_5
    ,af.early_lead_win_rate_last_5 AS away_early_lead_win_rate_last_5
    ,af.late_win_rate_last_5 AS away_late_win_rate_last_5
    ,af.late_loss_rate_last_5 AS away_late_loss_rate_last_5
    ,af.stoppage_win_rate_last_5 AS away_stoppage_win_rate_last_5
    ,af.lead_change_rate_last_5 AS away_lead_change_rate_last_5
    ,af.red_card_match_rate_last_5 AS away_red_card_match_rate_last_5
    ,af.early_red_card_rate_last_5 AS away_early_red_card_rate_last_5
    ,af.var_match_rate_last_5 AS away_var_match_rate_last_5
    ,af.disallowed_goal_rate_last_5 AS away_disallowed_goal_rate_last_5
    ,af.decisive_penalty_win_rate_last_5 AS away_decisive_penalty_win_rate_last_5
    ,af.decisive_own_goal_win_rate_last_5 AS away_decisive_own_goal_win_rate_last_5
    ,af.matches_last_10 AS away_matches_last_10
    ,af.win_rate_last_10 AS away_win_rate_last_10
    ,af.draw_rate_last_10 AS away_draw_rate_last_10
    ,af.goals_for_avg_last_10 AS away_goals_for_avg_last_10
    ,af.goals_against_avg_last_10 AS away_goals_against_avg_last_10
    ,af.goal_difference_avg_last_10 AS away_goal_difference_avg_last_10
    ,af.xg_difference_avg_last_10 AS away_xg_difference_avg_last_10
    ,af.comeback_win_rate_last_10 AS away_comeback_win_rate_last_10
    ,af.early_lead_win_rate_last_10 AS away_early_lead_win_rate_last_10
    ,af.late_win_rate_last_10 AS away_late_win_rate_last_10
    ,af.late_loss_rate_last_10 AS away_late_loss_rate_last_10
    ,af.red_card_match_rate_last_10 AS away_red_card_match_rate_last_10
    ,af.venue_matches_last_5 AS away_venue_matches_last_5
    ,af.venue_win_rate_last_5 AS away_venue_win_rate_last_5
    ,af.venue_draw_rate_last_5 AS away_venue_draw_rate_last_5
    ,af.venue_goals_for_avg_last_5 AS away_venue_goals_for_avg_last_5
    ,af.venue_goals_against_avg_last_5 AS away_venue_goals_against_avg_last_5
    ,af.venue_goal_difference_avg_last_5 AS away_venue_goal_difference_avg_last_5
    ,af.venue_xg_difference_avg_last_5 AS away_venue_xg_difference_avg_last_5
    ,af.venue_comeback_win_rate_last_5 AS away_venue_comeback_win_rate_last_5
    ,af.venue_late_win_rate_last_5 AS away_venue_late_win_rate_last_5
    ,af.venue_late_loss_rate_last_5 AS away_venue_late_loss_rate_last_5
    ,af.h2h_matches_last_5 AS away_h2h_matches_last_5
    ,af.h2h_win_rate_last_5 AS away_h2h_win_rate_last_5
    ,af.h2h_draw_rate_last_5 AS away_h2h_draw_rate_last_5
    ,af.h2h_goals_for_avg_last_5 AS away_h2h_goals_for_avg_last_5
    ,af.h2h_goals_against_avg_last_5 AS away_h2h_goals_against_avg_last_5
    ,af.h2h_goal_difference_avg_last_5 AS away_h2h_goal_difference_avg_last_5
    ,af.h2h_one_goal_match_rate_last_5 AS away_h2h_one_goal_match_rate_last_5
    ,af.h2h_comeback_win_rate_last_5 AS away_h2h_comeback_win_rate_last_5
    ,af.h2h_late_win_rate_last_5 AS away_h2h_late_win_rate_last_5
    ,af.h2h_late_loss_rate_last_5 AS away_h2h_late_loss_rate_last_5
FROM match_targets m
LEFT JOIN home_features hf
    ON hf.fixture_id = m.fixture_id AND hf.team_id = m.home_team_id
LEFT JOIN away_features af
    ON af.fixture_id = m.fixture_id AND af.team_id = m.away_team_id;
