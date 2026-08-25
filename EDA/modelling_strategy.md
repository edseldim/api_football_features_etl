## Modelling Approach

The problem will be modelled as a **multiclass probabilistic classification problem**, where each observation represents one Argentine Primera Division match at time (t).

The target variable is:

$
Y_t \in {\text{Home Win},\ \text{Draw},\ \text{Away Win}}
$

The model will estimate:

$
P(Y_t) = [P(H), P(D), P(A)]
$

For example:

| Outcome  | Probability |
| -------- | ----------: |
| Home Win |        0.52 |
| Draw     |        0.28 |
| Away Win |        0.20 |

Rather than simply predicting a class, the objective is therefore to estimate the probability of each possible match outcome.

## Features

Each row in the modelling dataset represents **one match**. The features for a match at time (t) describe the state of the home and away teams immediately before kickoff.

Conceptually:

$
X_t =
f(
\text{Home Team History}*{<t},
\text{Away Team History}*{<t},
\text{Match Context}_t
)
$

Historical information will be constructed from each team's previous matches $(t-1,t-2,\ldots,t-n)$. These observations can then be summarized into features describing recent form, underlying strength, home/away performance, rest, opponent strength, and other relevant characteristics.


## Notes

**Team independence.** Team and venue identifiers will be used to reconstruct historical information but will **not be provided to the classifier as features**. The intention is for the model to learn general football relationships rather than team-specific associations.

**Home/away asymmetry.** Home and away teams will be represented separately. Swapping the teams therefore creates a different observation, and the model is not required to produce symmetric probabilities after a swap.

If features are calculated using a fixed lookback period rather than a fixed number of previous matches, the minimum lookback window should be approximately 7×t days, where t is the desired number of historical matches. The 7-day interval reflects the typical scheduling frequency of league matches and helps ensure that the window captures approximately t previous league fixtures.

## Imputation Logic

Feature computations are allowed to cross season boundaries because matches from previous seasons are considered relevant historical information. For each match, these computations must still use only information that was available before kickoff.

For the first modelling iteration, all missing feature values will be imputed as `0`. This applies whether a value is missing because an event was structurally absent, a calculation was undefined due to insufficient history, or the data provider did not supply the observation.

This intentionally simple baseline may be replaced in future iterations by a more dynamic, team-aware imputation strategy. Such a strategy could account for the number, recency, and quality of a team's available historical observations, but zero imputation is considered sufficient for the initial model.

# WIP: (DESIGN FEATURES USING CODEX)


## Potential Biases


| Bias / issue | Stage | What to analyze | What you're trying to find | What you could do about it |
| - | - | - | - | - |
| **Class imbalance**              | EDA              | H/D/A frequencies overall and by season                                                           | Whether one outcome is much more common. Also whether the class distribution changes over time—for example, home wins falling from 45% to 39%.                                                                                            | Don't necessarily rebalance: the imbalance is real football information. Use appropriate probabilistic metrics such as multiclass log loss and compare against a baseline using historical H/D/A frequencies.                                                                       |
| **Temporal / concept drift**  | EDA with xG features                | H/D/A rates, goals, xG, shots, cards, possession, etc. by season/month                            | Whether football characteristics change over time. More importantly, whether relationships between features and outcomes change—for example, whether a +0.5 xG-strength advantage predicts something different in 2025 than in 2019.      | Use rolling training windows, give newer observations higher sample weights, create time-aware features, and use walk-forward validation. Compare 1-, 2-, 3-, 5-year and expanding windows.                                                                                         |
| **COVID structural break**          | EDA           | Compare pre-COVID, restricted-attendance and post-COVID periods                                   | Whether absence/reduction of crowds changed home advantage, goals, cards, referee behavior, etc. COVID matches may represent a football environment that no longer exists.                                                                | Test models with and without those matches. Alternatively downweight them or include a COVID/restricted-attendance indicator if you believe the period still contains useful relationships.                                                                                         |
| **Schedule congestion**       | Feature Engineering + Post training performance analysis                 | Days since previous match, matches in previous 7/14/30 days, recent continental/cup participation | Whether teams playing every 3–4 days perform differently from teams with a full week of rest. Raw form can otherwise mix underlying ability with temporary fatigue.                                                                       | Add `days_rest`, `matches_last_7d`, `matches_last_14d`, etc. Potentially distinguish domestic/continental congestion and long travel.                                                                                                                                               |
| **Home/away distribution bias**     | EDA           | Team performance overall vs home-only and away-only                                               | Whether some apparent team strength is actually venue-dependent. A team might have excellent overall form because four of its previous five games were home matches.                                                                      | Maintain separate overall, home and away rolling statistics. For a home team, consider its recent home performance; for an away team, recent away performance.                                                                                                                      |
| **Season-stage bias**        | Features                  | Outcomes/features by matchweek or % of competition completed                                      | Whether early-, mid- and late-season matches behave differently. Late-season incentives can differ because of title, relegation or qualification battles. Early-season rolling stats may mostly describe the previous season.             | Add season-progress/matchweek features where meaningful. Explicitly decide how rolling features cross season boundaries. Potentially include incentive-related variables if they can be constructed without leakage.                                                                |
| **Sample-selection bias from strong clubs** | EDA   | Number of observations per team and competition                                                   | Strong teams participate in more competitions and therefore generate more observations. If all competitions enter training, clubs like River/Boca can indirectly dominate the dataset even without team-name features.                    | Inspect observation counts and weights by club. Restrict classifier training to your prediction universe, cap/weight observations where justified, and validate performance across different team-strength groups.                                                                  |
| **Team-independent model bias**   | Post training performance analysis             | Out-of-sample log loss/calibration by team, promoted status, strength tier, etc.                  | Whether your supposedly general model systematically works better for certain kinds of teams. You might discover excellent predictions for established clubs but poor ones for newly promoted or volatile teams.                          | Evaluate metrics by subgroup. Investigate which features fail to describe problematic teams. Add generalizable features such as strength-of-schedule rather than adding team identity.                                                                                              |                                                                                |
