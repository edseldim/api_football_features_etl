"""Select features by their statistical association with the target."""

from math import exp, isfinite, sqrt
from pathlib import Path
from typing import Any

import pandas as pd
from scipy.stats import chi2_contingency, f as f_distribution, kruskal
from sklearn.ensemble import RandomForestClassifier
from sklearn.feature_selection import RFE, mutual_info_classif

from .ETLHelper import ETLHelper


class FeatureSelection:
    """Score and retain features associated with a classification target."""

    VALID_FEATURE_TYPES = {"integer", "continuous", "categorical"}

    def __init__(self, etl_helper: ETLHelper) -> None:
        """Initialize the step with shared resources and configuration."""
        if not isinstance(etl_helper, ETLHelper):
            raise TypeError("etl_helper must be an initialized ETLHelper")

        self.etl_helper = etl_helper
        self.params = dict(etl_helper.params.get("FeatureSelection", {}))
        self.params.update(etl_helper.params.get("Global", {}))

    def get_imputed_dataset(self) -> pd.DataFrame:
        """Return the imputed dataset produced by the preceding ETL step."""
        payload = self.etl_helper.get_payload()
        imputed_dataset = payload.get("imputed_dataset")
        if not isinstance(imputed_dataset, pd.DataFrame):
            raise ValueError(
                "ETLHelper payload must contain an 'imputed_dataset' DataFrame"
            )
        if imputed_dataset.empty:
            raise ValueError("The imputed dataset must not be empty")
        return imputed_dataset

    def load_feature_catalog(self) -> pd.DataFrame:
        """Load the configured feature/feature_type catalog CSV."""
        configured_path = self.params.get("feature_catalog_path")
        if not isinstance(configured_path, str) or not configured_path:
            raise ValueError(
                "FeatureSelection.feature_catalog_path must be a non-empty string"
            )

        catalog_path = Path(self.etl_helper.data_path, configured_path)
        if catalog_path.suffix.lower() != ".csv":
            raise ValueError("FeatureSelection.feature_catalog_path must be a CSV file")
        if not catalog_path.is_file():
            raise FileNotFoundError(f"Feature catalog not found: {catalog_path}")
        catalog = pd.read_csv(catalog_path)

        required_columns = {"feature", "feature_type"}
        missing_columns = required_columns.difference(catalog.columns)
        if missing_columns:
            missing = ", ".join(sorted(missing_columns))
            raise ValueError(f"Feature catalog is missing required columns: {missing}")

        catalog = catalog.loc[:, ["feature", "feature_type"]].copy()
        if catalog.empty:
            raise ValueError("Feature catalog must not be empty")
        if catalog.isna().any().any():
            raise ValueError("Feature catalog cannot contain null values")

        catalog["feature"] = catalog["feature"].astype(str).str.strip()
        catalog["feature_type"] = (
            catalog["feature_type"].astype(str).str.strip().str.lower()
        )
        if (catalog["feature"] == "").any():
            raise ValueError("Feature names must not be empty")
        if catalog["feature"].duplicated().any():
            duplicates = catalog.loc[
                catalog["feature"].duplicated(keep=False), "feature"
            ].unique()
            raise ValueError(
                "Feature catalog contains duplicate features: "
                + ", ".join(sorted(duplicates))
            )

        invalid_types = set(catalog["feature_type"]).difference(
            self.VALID_FEATURE_TYPES
        )
        if invalid_types:
            raise ValueError(
                "Unsupported feature_type values: "
                + ", ".join(sorted(invalid_types))
            )
        return catalog

    def _validate_inputs(
        self,
        imputed_dataset: pd.DataFrame,
        feature_catalog: pd.DataFrame,
    ) -> tuple[str, int]:
        """Validate configuration and dataset/catalog compatibility."""
        target = self.params.get("target", "target")
        random_state = self.params.get("random_state", 42)

        if not isinstance(target, str) or not target:
            raise ValueError("FeatureSelection.target must be a non-empty string")
        if target not in imputed_dataset.columns:
            raise ValueError(f"Target column '{target}' is missing from the dataset")
        if imputed_dataset[target].isna().any():
            raise ValueError(f"Target column '{target}' cannot contain null values")
        if imputed_dataset[target].nunique(dropna=False) < 2:
            raise ValueError(
                f"Target column '{target}' must contain at least 2 classes"
            )

        if not isinstance(random_state, int) or isinstance(random_state, bool):
            raise TypeError("FeatureSelection.random_state must be an integer")

        features = feature_catalog["feature"].tolist()
        if target in features:
            raise ValueError("The target column cannot also be listed as a feature")
        missing_features = sorted(set(features).difference(imputed_dataset.columns))
        if missing_features:
            raise ValueError(
                "Catalog features missing from the imputed dataset: "
                + ", ".join(missing_features)
            )
        null_features = [
            feature for feature in features if imputed_dataset[feature].isna().any()
        ]
        if null_features:
            raise ValueError(
                "Imputed features still contain null values: "
                + ", ".join(sorted(null_features))
            )

        return target, random_state

    @staticmethod
    def linfoot_correlation(mutual_information: float) -> float:
        """Convert mutual information to Linfoot's correlation coefficient."""
        return sqrt(1.0 - exp(-2.0 * max(float(mutual_information), 0.0)))

    @staticmethod
    def cramers_v(contingency_table: pd.DataFrame, chi_squared: float) -> float:
        """Calculate Cramer's V from a contingency table and chi-square value."""
        observations = float(contingency_table.to_numpy().sum())
        degrees = min(contingency_table.shape) - 1
        if observations == 0 or degrees <= 0:
            return 0.0
        return sqrt(max(float(chi_squared), 0.0) / (observations * degrees))

    def categorize_linfoot_corr(self, association: float) -> str:
        """Map an association coefficient to hardcoded strength bands."""
        if pd.isna(association) or association < 0.1:
            return "negligible"
        if association < 0.3:
            return "weak"
        if association < 0.5:
            return "moderate"
        if association < 0.7:
            return "strong"
        return "very_strong"

    @staticmethod
    def classify_eta_squared(effect_size: float) -> str:
        """Classify the hardcoded one-way ANOVA eta-squared bands."""
        if pd.isna(effect_size) or effect_size < 0.01:
            return "no relevance"
        if effect_size < 0.06:
            return "small relevance"
        if effect_size < 0.14:
            return "medium relevance"
        return "high relevance"

    @staticmethod
    def classify_epsilon_squared(effect_size: float) -> str:
        """Classify the hardcoded Kruskal-Wallis epsilon-squared bands."""
        if pd.isna(effect_size) or effect_size < 0.01:
            return "no relevance"
        if effect_size < 0.08:
            return "small relevance"
        if effect_size < 0.26:
            return "medium relevance"
        return "high relevance"

    def score_continuous_group_differences(
        self,
        imputed_dataset: pd.DataFrame,
        feature_catalog: pd.DataFrame,
        target: str,
        random_state: int,
    ) -> pd.DataFrame:
        """Run MI, one-way ANOVA, and Kruskal-Wallis per numeric feature."""
        numeric_catalog = feature_catalog[
            feature_catalog["feature_type"].isin(["integer", "continuous"])
        ]
        result_columns = [
            "feature",
            "catalog_feature_type",
            "feature_type",
            "mutual_information",
            "linfoot_correlation",
            "strength",
            "anova_f_statistic",
            "anova_p_value",
            "eta_squared",
            "anova_relevance",
            "kruskal_h_statistic",
            "kruskal_p_value",
            "epsilon_squared",
            "kruskal_relevance",
        ]
        if numeric_catalog.empty:
            return pd.DataFrame(columns=result_columns)

        feature_names = numeric_catalog["feature"].tolist()
        numeric_data = imputed_dataset.loc[:, feature_names].apply(
            pd.to_numeric, errors="raise"
        )
        max_discrete_cardinality = self.params.get("max_discrete_cardinality", 50)
        if not isinstance(max_discrete_cardinality, int) or isinstance(
            max_discrete_cardinality, bool
        ):
            raise TypeError(
                "FeatureSelection.max_discrete_cardinality must be an integer"
            )
        if max_discrete_cardinality < 2:
            raise ValueError(
                "FeatureSelection.max_discrete_cardinality must be at least 2"
            )

        discrete_features: list[bool] = []
        effective_feature_types: list[str] = []
        reclassified_features: list[str] = []
        for row in numeric_catalog.itertuples(index=False):
            values = numeric_data[row.feature]
            is_integer_valued = values.eq(values.round()).all()
            is_low_cardinality = (
                values.nunique(dropna=False) <= max_discrete_cardinality
            )
            is_discrete = (
                row.feature_type == "integer"
                and is_integer_valued
                and is_low_cardinality
            )
            discrete_features.append(bool(is_discrete))
            effective_feature_types.append(
                "integer" if is_discrete else "continuous"
            )
            if row.feature_type == "integer" and not is_discrete:
                reclassified_features.append(row.feature)

        if reclassified_features:
            preview = ", ".join(reclassified_features[:20])
            remaining = len(reclassified_features) - 20
            if remaining > 0:
                preview += f", ... (+{remaining} more)"
            self.etl_helper.logger.log_event(
                "INFO",
                "Dynamically treating cataloged integer features as continuous "
                "because they contain fractional values or exceed "
                f"{max_discrete_cardinality} unique values: {preview}",
            )

        mutual_information = mutual_info_classif(
            numeric_data,
            imputed_dataset[target],
            discrete_features=discrete_features,
            random_state=random_state,
        )

        target_values = imputed_dataset[target]
        target_classes = target_values.unique()
        class_count = len(target_classes)
        observation_count = len(target_values)
        degrees_between = class_count - 1
        degrees_within = observation_count - class_count
        if class_count < 2:
            raise ValueError("Continuous feature tests require at least 2 classes")

        rows: list[dict[str, Any]] = []
        for feature_index, catalog_row in enumerate(
            numeric_catalog.itertuples(index=False)
        ):
            feature = catalog_row.feature
            values = numeric_data[feature]
            groups = [
                values.loc[target_values == target_class].to_numpy()
                for target_class in target_classes
            ]
            overall_mean = values.mean()
            total_sum_squares = float(((values - overall_mean) ** 2).sum())
            between_sum_squares = float(
                sum(
                    len(group) * (float(group.mean()) - overall_mean) ** 2
                    for group in groups
                )
            )
            within_sum_squares = max(
                total_sum_squares - between_sum_squares, 0.0
            )

            if total_sum_squares == 0 or degrees_within <= 0:
                anova_f_statistic = float("nan")
                anova_p_value = float("nan")
                eta_squared = float("nan")
                kruskal_h_statistic = float("nan")
                kruskal_p_value = float("nan")
                epsilon_squared = float("nan")
            else:
                eta_squared = between_sum_squares / total_sum_squares
                mean_square_between = between_sum_squares / degrees_between
                mean_square_within = within_sum_squares / degrees_within
                if mean_square_within == 0:
                    anova_f_statistic = float("inf")
                    anova_p_value = 0.0
                else:
                    anova_f_statistic = mean_square_between / mean_square_within
                    anova_p_value = float(
                        f_distribution.sf(
                            anova_f_statistic,
                            degrees_between,
                            degrees_within,
                        )
                    )

                kruskal_result = kruskal(*groups)
                kruskal_h_statistic = float(kruskal_result.statistic)
                kruskal_p_value = float(kruskal_result.pvalue)
                epsilon_squared = max(
                    0.0,
                    (kruskal_h_statistic - class_count + 1) / degrees_within,
                )

            feature_mutual_information = float(mutual_information[feature_index])
            linfoot_correlation = self.linfoot_correlation(
                feature_mutual_information
            )
            rows.append(
                {
                    "feature": feature,
                    "catalog_feature_type": catalog_row.feature_type,
                    "feature_type": effective_feature_types[feature_index],
                    "mutual_information": feature_mutual_information,
                    "linfoot_correlation": linfoot_correlation,
                    "strength": self.categorize_linfoot_corr(linfoot_correlation),
                    "anova_f_statistic": anova_f_statistic,
                    "anova_p_value": anova_p_value,
                    "eta_squared": eta_squared,
                    "anova_relevance": self.classify_eta_squared(eta_squared),
                    "kruskal_h_statistic": kruskal_h_statistic,
                    "kruskal_p_value": kruskal_p_value,
                    "epsilon_squared": epsilon_squared,
                    "kruskal_relevance": self.classify_epsilon_squared(
                        epsilon_squared
                    ),
                }
            )

        return pd.DataFrame(rows, columns=result_columns)

    def filter_features_by_metrics(
        self,
        imputed_dataset: pd.DataFrame,
        continuous_scores: pd.DataFrame,
        categorical_scores: pd.DataFrame,
    ) -> tuple[pd.DataFrame, pd.DataFrame, list[str]]:
        """Apply target-association and correlation filters before RFE."""
        mutual_information_threshold = self.params.get(
            "mutual_information_threshold"
        )
        cramers_v_threshold = self.params.get("cramers_v_threshold")

        if not isinstance(
            mutual_information_threshold, (int, float)
        ) or isinstance(mutual_information_threshold, bool):
            raise TypeError(
                "FeatureSelection.mutual_information_threshold must be numeric"
            )
        if not isfinite(float(mutual_information_threshold)) or float(
            mutual_information_threshold
        ) < 0:
            raise ValueError(
                "FeatureSelection.mutual_information_threshold must be a finite "
                "nonnegative number"
            )
        if not isinstance(cramers_v_threshold, (int, float)) or isinstance(
            cramers_v_threshold, bool
        ):
            raise TypeError("FeatureSelection.cramers_v_threshold must be numeric")
        if not 0 <= float(cramers_v_threshold) <= 1:
            raise ValueError(
                "FeatureSelection.cramers_v_threshold must be between 0 and 1"
            )

        continuous_results = continuous_scores.loc[
            :, ["feature", "feature_type", "mutual_information"]
        ].copy()
        continuous_results["prefilter_method"] = "mutual_information"
        continuous_results["prefilter_score"] = continuous_results[
            "mutual_information"
        ]
        continuous_results["prefilter_threshold"] = float(
            mutual_information_threshold
        )
        continuous_results = continuous_results.drop(
            columns="mutual_information"
        )

        categorical_results = categorical_scores.loc[
            :, ["feature", "feature_type", "cramers_v"]
        ].copy()
        categorical_results["prefilter_method"] = "cramers_v"
        categorical_results["prefilter_score"] = categorical_results["cramers_v"]
        categorical_results["prefilter_threshold"] = float(cramers_v_threshold)
        categorical_results = categorical_results.drop(columns="cramers_v")

        results = pd.concat(
            [continuous_results, categorical_results], ignore_index=True
        )
        results["passed_prefilter"] = (
            results["prefilter_score"] >= results["prefilter_threshold"]
        )
        results = self.filter_correlated_features(imputed_dataset, results)
        correlation_columns = [
            "correlation_filter_selected",
            "correlated_with",
            "feature_pair_association",
            "feature_pair_method",
        ]
        correlation_filter_results = results.loc[
            results["passed_prefilter"],
            [
                "feature",
                "feature_type",
                "prefilter_method",
                "prefilter_score",
                "prefilter_threshold",
                *correlation_columns,
            ],
        ].reset_index(drop=True)
        candidate_features = correlation_filter_results.loc[
            correlation_filter_results["correlation_filter_selected"],
            "feature",
        ].tolist()
        correlation_filter_results = correlation_filter_results.sort_values(
            ["correlation_filter_selected", "prefilter_score"],
            ascending=[False, False],
            ignore_index=True,
        )
        results = results.drop(
            columns=[
                *correlation_columns,
                "prefilter_method",
                "prefilter_score",
                "prefilter_threshold",
                "passed_prefilter",
            ]
        )
        return results, correlation_filter_results, candidate_features

    def run_rfe_feature_selection(
        self,
        imputed_dataset: pd.DataFrame,
        feature_filter_results: pd.DataFrame,
        candidate_features: list[str],
        target: str,
        random_state: int,
    ) -> pd.DataFrame:
        """Run recursive feature elimination on the filtered candidates."""
        features_to_select = self.params.get("rfe_features_to_select")
        if not isinstance(features_to_select, int) or isinstance(
            features_to_select, bool
        ):
            raise TypeError(
                "FeatureSelection.rfe_features_to_select must be an integer"
            )
        if features_to_select < 1:
            raise ValueError(
                "FeatureSelection.rfe_features_to_select must be at least 1"
            )

        results = feature_filter_results.copy()
        results["rfe_selected"] = False
        results["rfe_ranking"] = pd.Series(pd.NA, index=results.index, dtype="Int64")
        results["feature_importance"] = float("nan")

        if not candidate_features:
            self.etl_helper.logger.log_event(
                "INFO",
                "RFE skipped because no features passed threshold and correlation "
                "filtering",
            )
            return results

        effective_features_to_select = min(
            features_to_select, len(candidate_features)
        )
        if effective_features_to_select < features_to_select:
            self.etl_helper.logger.log_event(
                "INFO",
                "RFE requested more features than passed prefiltering; selecting "
                f"all {effective_features_to_select} candidate features",
            )

        candidate_data = imputed_dataset.loc[:, candidate_features].apply(
            pd.to_numeric, errors="raise"
        )
        estimator = RandomForestClassifier(
            n_estimators=100,
            class_weight="balanced",
            random_state=random_state,
            n_jobs=-1,
        )
        selector = RFE(
            estimator=estimator,
            n_features_to_select=effective_features_to_select,
            step=0.1,
            importance_getter="feature_importances_",
        )
        selector.fit(candidate_data, imputed_dataset[target])

        candidate_index = results["feature"].isin(candidate_features)
        results.loc[candidate_index, "rfe_selected"] = selector.support_
        results.loc[candidate_index, "rfe_ranking"] = selector.ranking_
        selected_features = [
            feature
            for feature, selected in zip(candidate_features, selector.support_)
            if selected
        ]
        importance_by_feature = dict(
            zip(selected_features, selector.estimator_.feature_importances_)
        )
        results["feature_importance"] = results["feature"].map(
            importance_by_feature
        )
        rfe_results = results.sort_values(
            ["rfe_selected", "feature_importance", "rfe_ranking", "feature"],
            ascending=[False, False, True, True],
            na_position="last",
            ignore_index=True,
        )
        return rfe_results

    def filter_correlated_features(
        self,
        imputed_dataset: pd.DataFrame,
        prefilter_results: pd.DataFrame,
    ) -> pd.DataFrame:
        """Keep the strongest target-associated feature from redundant pairs."""
        threshold = self.params.get("high_correlation_threshold", 0.8)
        if not isinstance(threshold, (int, float)) or isinstance(threshold, bool):
            raise TypeError(
                "FeatureSelection.high_correlation_threshold must be numeric"
            )
        threshold = float(threshold)
        if not 0 <= threshold <= 1:
            raise ValueError(
                "FeatureSelection.high_correlation_threshold must be between 0 and 1"
            )

        results = prefilter_results.copy()
        results["correlation_filter_selected"] = False
        results["correlated_with"] = pd.NA
        results["feature_pair_association"] = float("nan")
        results["feature_pair_method"] = pd.NA

        candidates = results.loc[results["passed_prefilter"]].sort_values(
            ["prefilter_score", "feature"],
            ascending=[False, True],
        )
        retained: list[tuple[str, str]] = []
        for row in candidates.itertuples(index=False):
            feature_family = (
                "categorical" if row.feature_type == "categorical" else "numeric"
            )
            redundant_with: str | None = None
            pair_association = 0.0
            pair_method: str | None = None

            for retained_feature, retained_family in retained:
                if feature_family != retained_family:
                    continue
                if feature_family == "numeric":
                    pair_data = imputed_dataset.loc[
                        :, [row.feature, retained_feature]
                    ].apply(pd.to_numeric, errors="raise")
                    pearson = pair_data.corr(method="pearson").iloc[0, 1]
                    spearman = pair_data.corr(method="spearman").iloc[0, 1]
                    pearson = 0.0 if pd.isna(pearson) else abs(float(pearson))
                    spearman = 0.0 if pd.isna(spearman) else abs(float(spearman))
                    association = max(pearson, spearman)
                    method = "pearson" if pearson >= spearman else "spearman"
                else:
                    contingency = pd.crosstab(
                        imputed_dataset[row.feature],
                        imputed_dataset[retained_feature],
                    )
                    if min(contingency.shape) < 2:
                        association = 0.0
                    else:
                        chi_squared, _, _, _ = chi2_contingency(contingency)
                        association = self.cramers_v(contingency, chi_squared)
                    method = "cramers_v"

                if association >= threshold:
                    redundant_with = retained_feature
                    pair_association = association
                    pair_method = method
                    break

            feature_index = results["feature"].eq(row.feature)
            if redundant_with is None:
                results.loc[
                    feature_index, "correlation_filter_selected"
                ] = True
                retained.append((row.feature, feature_family))
            else:
                results.loc[feature_index, "correlated_with"] = redundant_with
                results.loc[
                    feature_index, "feature_pair_association"
                ] = pair_association
                results.loc[feature_index, "feature_pair_method"] = pair_method

        removed_count = int(
            (
                results["passed_prefilter"]
                & ~results["correlation_filter_selected"]
            ).sum()
        )
        if removed_count:
            self.etl_helper.logger.log_event(
                "INFO",
                "Removed redundant features before RFE by retaining the higher "
                "target-association score from each correlated pair "
                f"| count={removed_count} | threshold={threshold}",
            )
        return results

    def score_categorical_features(
        self,
        imputed_dataset: pd.DataFrame,
        feature_catalog: pd.DataFrame,
        target: str,
    ) -> pd.DataFrame:
        """Score categorical features with chi-square and Cramer's V."""
        categorical_catalog = feature_catalog[
            feature_catalog["feature_type"].eq("categorical")
        ]
        result_columns = [
            "feature",
            "feature_type",
            "chi_squared",
            "p_value",
            "degrees_of_freedom",
            "cramers_v",
            "strength",
        ]
        rows: list[dict[str, Any]] = []
        for row in categorical_catalog.itertuples(index=False):
            contingency = pd.crosstab(
                imputed_dataset[row.feature], imputed_dataset[target]
            )
            if min(contingency.shape) < 2:
                chi_squared, p_value, degrees_of_freedom = 0.0, 1.0, 0
            else:
                chi_squared, p_value, degrees_of_freedom, _ = chi2_contingency(
                    contingency
                )
            association = self.cramers_v(contingency, chi_squared)
            rows.append(
                {
                    "feature": row.feature,
                    "feature_type": row.feature_type,
                    "chi_squared": float(chi_squared),
                    "p_value": float(p_value),
                    "degrees_of_freedom": int(degrees_of_freedom),
                    "cramers_v": association,
                    "strength": self.categorize_linfoot_corr(association),
                }
            )
        return pd.DataFrame(rows, columns=result_columns)

    def calculate_high_correlations(
        self,
        imputed_dataset: pd.DataFrame,
        feature_catalog: pd.DataFrame,
    ) -> pd.DataFrame:
        """Return pairs with high absolute Pearson or Spearman correlation."""
        threshold = self.params.get("high_correlation_threshold", 0.8)
        if not isinstance(threshold, (int, float)) or isinstance(threshold, bool):
            raise TypeError(
                "FeatureSelection.high_correlation_threshold must be numeric"
            )
        threshold = float(threshold)
        if not 0 <= threshold <= 1:
            raise ValueError(
                "FeatureSelection.high_correlation_threshold must be between 0 and 1"
            )

        numeric_features = feature_catalog.loc[
            feature_catalog["feature_type"].isin(["integer", "continuous"]),
            "feature",
        ].tolist()
        result_columns = [
            "feature_1",
            "feature_2",
            "pearson_correlation",
            "absolute_pearson_correlation",
            "spearman_correlation",
            "absolute_spearman_correlation",
            "maximum_absolute_correlation",
        ]
        if len(numeric_features) < 2:
            return pd.DataFrame(columns=result_columns)

        numeric_data = imputed_dataset.loc[:, numeric_features].apply(
            pd.to_numeric, errors="raise"
        )
        pearson_matrix = numeric_data.corr(method="pearson")
        spearman_matrix = numeric_data.corr(method="spearman")
        pairs: list[dict[str, Any]] = []
        for first_index, first_feature in enumerate(numeric_features):
            for second_feature in numeric_features[first_index + 1 :]:
                pearson = pearson_matrix.at[first_feature, second_feature]
                spearman = spearman_matrix.at[first_feature, second_feature]
                absolute_pearson = 0.0 if pd.isna(pearson) else abs(float(pearson))
                absolute_spearman = (
                    0.0 if pd.isna(spearman) else abs(float(spearman))
                )
                maximum_correlation = max(absolute_pearson, absolute_spearman)
                if maximum_correlation < threshold:
                    continue
                pairs.append(
                    {
                        "feature_1": first_feature,
                        "feature_2": second_feature,
                        "pearson_correlation": (
                            float(pearson) if not pd.isna(pearson) else float("nan")
                        ),
                        "absolute_pearson_correlation": absolute_pearson,
                        "spearman_correlation": (
                            float(spearman)
                            if not pd.isna(spearman)
                            else float("nan")
                        ),
                        "absolute_spearman_correlation": absolute_spearman,
                        "maximum_absolute_correlation": maximum_correlation,
                    }
                )

        return pd.DataFrame(pairs, columns=result_columns).sort_values(
            "maximum_absolute_correlation", ascending=False, ignore_index=True
        )

    def _output_path(self, parameter: str, default_file_name: str) -> Path:
        """Resolve an output filename beneath the ETLHelper data root."""
        data_root = Path(self.etl_helper.data_path).expanduser().resolve()
        output_directory = self.params.get("output_directory", "outputs")
        file_name = self.params.get(parameter, default_file_name)
        if not isinstance(output_directory, (str, Path)) or not str(output_directory):
            raise ValueError(
                "FeatureSelection.output_directory must be a relative path"
            )
        relative_output_directory = Path(output_directory)
        if relative_output_directory.is_absolute() or ".." in (
            relative_output_directory.parts
        ):
            raise ValueError(
                "FeatureSelection.output_directory must remain inside "
                "ETLHelper.data_path"
            )
        if (
            not isinstance(file_name, str)
            or not file_name
            or Path(file_name).name != file_name
            or Path(file_name).suffix.lower() != ".csv"
        ):
            raise ValueError(f"FeatureSelection.{parameter} must be a CSV filename")
        return data_root / relative_output_directory / file_name

    def write_selected_features(
        self,
        continuous_features: pd.DataFrame,
        categorical_features: pd.DataFrame,
    ) -> dict[str, Path]:
        """Write both selected feature catalogs to CSV."""
        continuous_path = self._output_path(
            "continuous_output_file", "selected_continuous_features.csv"
        )
        categorical_path = self._output_path(
            "categorical_output_file", "selected_categorical_features.csv"
        )
        continuous_path.parent.mkdir(parents=True, exist_ok=True)
        categorical_path.parent.mkdir(parents=True, exist_ok=True)
        continuous_features.to_csv(continuous_path, index=False)
        categorical_features.to_csv(categorical_path, index=False)
        return {
            "continuous": continuous_path,
            "categorical": categorical_path,
        }

    def write_high_correlations(self, high_correlations: pd.DataFrame) -> Path:
        """Write highly correlated numeric-feature pairs to CSV."""
        output_path = self._output_path(
            "correlation_output_file", "highly_correlated_features.csv"
        )
        output_path.parent.mkdir(parents=True, exist_ok=True)
        high_correlations.to_csv(output_path, index=False)
        return output_path

    def write_rfe_results(self, rfe_results: pd.DataFrame) -> Path:
        """Write prefiltering, RFE ranking, and feature importance to CSV."""
        output_path = self._output_path(
            "rfe_output_file", "rfe_feature_selection.csv"
        )
        output_path.parent.mkdir(parents=True, exist_ok=True)
        rfe_results.to_csv(output_path, index=False)
        return output_path

    def write_correlation_filter_results(
        self, correlation_filter_results: pd.DataFrame
    ) -> Path:
        """Write correlation-filter decisions to their own CSV report."""
        output_path = self._output_path(
            "correlation_filter_output_file",
            "correlation_filtered_features.csv",
        )
        output_path.parent.mkdir(parents=True, exist_ok=True)
        correlation_filter_results.to_csv(output_path, index=False)
        return output_path

    def run(self) -> dict[str, Any]:
        """Score, filter, and export cataloged features by feature type."""
        self.etl_helper.logger.log_event("INFO", "Feature selection started")

        try:
            imputed_dataset = self.get_imputed_dataset()
            catalog = self.load_feature_catalog()
            excluded_features = self.etl_helper.get_payload().get(
                "imputation_excluded_features", []
            )
            if not isinstance(excluded_features, list) or not all(
                isinstance(feature, str) for feature in excluded_features
            ):
                raise TypeError(
                    "imputation_excluded_features payload value must be a list "
                    "of feature names"
                )
            if excluded_features:
                catalog = catalog.loc[
                    ~catalog["feature"].isin(excluded_features)
                ].reset_index(drop=True)
                self.etl_helper.logger.log_event(
                    "INFO",
                    "Removed features excluded by the imputation-percentage filter "
                    f"from the selection catalog | count={len(excluded_features)}",
                )
            target, random_state = self._validate_inputs(imputed_dataset, catalog)

            continuous_scores = self.score_continuous_group_differences(
                imputed_dataset, catalog, target, random_state
            )
            categorical_scores = self.score_categorical_features(
                imputed_dataset, catalog, target
            )
            high_correlations = self.calculate_high_correlations(
                imputed_dataset, catalog
            )
            (
                feature_filter_results,
                correlation_filter_results,
                candidate_features,
            ) = self.filter_features_by_metrics(
                imputed_dataset,
                continuous_scores,
                categorical_scores,
            )
            rfe_results = self.run_rfe_feature_selection(
                imputed_dataset,
                feature_filter_results,
                candidate_features,
                target,
                random_state,
            )
            selected_continuous = continuous_scores.sort_values(
                "linfoot_correlation", ascending=False
            )
            selected_categorical = categorical_scores.sort_values(
                "cramers_v", ascending=False
            )

            output_paths = self.write_selected_features(
                selected_continuous, selected_categorical
            )
            output_paths["high_correlations"] = self.write_high_correlations(
                high_correlations
            )
            output_paths["rfe"] = self.write_rfe_results(rfe_results)
            output_paths["correlation_filter"] = (
                self.write_correlation_filter_results(
                    correlation_filter_results
                )
            )
            result = {
                "continuous_features": selected_continuous.reset_index(drop=True),
                "categorical_features": selected_categorical.reset_index(drop=True),
                "high_correlations": high_correlations,
                "correlation_filtered_features": correlation_filter_results,
                "rfe_features": rfe_results,
                "output_paths": output_paths,
            }
            payload = self.etl_helper.get_payload().copy()
            payload["selected_features"] = result
            self.etl_helper.set_payload(payload)

            self.etl_helper.logger.log_event(
                "INFO",
                "Feature selection completed "
                f"| continuous={len(selected_continuous)} "
                f"| categorical={len(selected_categorical)} "
                f"| rfe_selected={int(rfe_results['rfe_selected'].sum())} "
                f"| high_correlation_pairs={len(high_correlations)}",
            )
            return result
        except Exception as exc:
            self.etl_helper.logger.log_event(
                "ERROR", f"Feature selection failed: {exc}"
            )
            raise
