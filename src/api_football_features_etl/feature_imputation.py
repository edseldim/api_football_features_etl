"""Fit feature imputation on training data and apply it to every dataset split."""

from collections.abc import Mapping
from typing import Any

import pandas as pd

from .ETLHelper import ETLHelper


DATASET_NAMES = ("train", "val", "test", "oot")
BASE_TABLE_ALIAS = "league_features"
FIXTURE_ID_COLUMN = "fixture_id"
DATE_COLUMN = "date"


class FeatureImputation:
    """Create leakage-safe metadata and per-source imputed dataset tables."""

    def __init__(self, etl_helper: ETLHelper) -> None:
        """Initialize the step with shared resources and configuration."""
        if not isinstance(etl_helper, ETLHelper):
            raise TypeError("etl_helper must be an initialized ETLHelper")

        self.etl_helper = etl_helper
        self.params = {
            **etl_helper.params.get("Global", {}),
            **etl_helper.params.get("FeatureImputation", {}),
        }

    def _validated_settings(
        self,
    ) -> tuple[Mapping[str, str], list[str], str, str, float]:
        """Validate and return settings shared by the imputation stages."""
        feature_tables = self.params.get("feature_tables")
        key_features = self.params.get("key_features")
        schema = self.params.get("schema", "public")
        metadata_table = self.params.get(
            "imputation_metadata_tbl",
            self.params.get("imputation_percentage_tbl"),
        )
        imputation_filter = self.params.get("imputation_percentage_filter")

        if not isinstance(feature_tables, Mapping) or not feature_tables:
            raise ValueError("feature_tables must be a non-empty configuration object")
        if BASE_TABLE_ALIAS not in feature_tables:
            raise ValueError(
                f"feature_tables must contain a '{BASE_TABLE_ALIAS}' alias"
            )
        if not all(
            isinstance(alias, str)
            and alias
            and isinstance(table_name, str)
            and table_name
            for alias, table_name in feature_tables.items()
        ):
            raise ValueError(
                "Feature table aliases and names must be non-empty strings"
            )
        if not isinstance(key_features, list) or not all(
            isinstance(column, str) and column for column in key_features
        ):
            raise ValueError("key_features must be a list of column names")
        if not isinstance(schema, str) or not schema:
            raise ValueError("schema must be a non-empty string")
        if not isinstance(metadata_table, str) or not metadata_table:
            raise ValueError(
                "imputation_metadata_tbl must be a non-empty table name"
            )
        if not isinstance(imputation_filter, (int, float)) or isinstance(
            imputation_filter, bool
        ):
            raise TypeError("imputation_percentage_filter must be numeric")

        imputation_filter = float(imputation_filter)
        if not 0 <= imputation_filter <= 1:
            raise ValueError("imputation_percentage_filter must be between 0 and 1")

        return (
            feature_tables,
            key_features,
            schema,
            metadata_table,
            imputation_filter,
        )

    def _date_segments(self) -> dict[str, tuple[pd.Timestamp, pd.Timestamp]]:
        """Validate configured inclusive date ranges for all dataset splits."""
        segments: dict[str, tuple[pd.Timestamp, pd.Timestamp]] = {}

        for dataset_name in DATASET_NAMES:
            configured_range = self.params.get(dataset_name)
            if (
                not isinstance(configured_range, (list, tuple))
                or len(configured_range) != 2
                or not all(
                    isinstance(value, str) and value
                    for value in configured_range
                )
            ):
                raise ValueError(
                    f"{dataset_name} must contain [start_date, end_date]"
                )

            try:
                start = (
                    pd.to_datetime(configured_range[0], errors="raise", utc=True)
                    .tz_localize(None)
                    .normalize()
                )
                end = (
                    pd.to_datetime(configured_range[1], errors="raise", utc=True)
                    .tz_localize(None)
                    .normalize()
                )
            except (TypeError, ValueError) as exc:
                raise ValueError(
                    f"{dataset_name} contains an invalid date range: "
                    f"{configured_range}"
                ) from exc

            if start > end:
                raise ValueError(
                    f"{dataset_name} start date must not be after its end date"
                )
            segments[dataset_name] = (start, end)

        ordered_segments = sorted(segments.items(), key=lambda item: item[1][0])
        for (left_name, (_, left_end)), (right_name, (right_start, _)) in zip(
            ordered_segments,
            ordered_segments[1:],
        ):
            if right_start <= left_end:
                raise ValueError(
                    f"Dataset date ranges overlap: {left_name} and {right_name}"
                )

        return segments

    def _download_table(self, table_name: str, schema: str) -> pd.DataFrame:
        """Download a configured table, accepting a schema-qualified name."""
        unqualified_name = self._unqualified_table_name(table_name, schema)
        return self.etl_helper.database_connection.download_table(
            unqualified_name,
            schema=schema,
        )

    @staticmethod
    def _unqualified_table_name(table_name: str, schema: str) -> str:
        """Remove the configured schema prefix from a table name."""
        qualified_prefix = f"{schema}."
        return (
            table_name[len(qualified_prefix) :]
            if table_name.startswith(qualified_prefix)
            else table_name
        )

    @staticmethod
    def _validate_fixture_ids(
        dataframe: pd.DataFrame,
        qualified_table_name: str,
    ) -> None:
        """Require one non-null fixture row per table."""
        if FIXTURE_ID_COLUMN not in dataframe.columns:
            raise ValueError(
                f"Feature table '{qualified_table_name}' has no "
                f"{FIXTURE_ID_COLUMN} column"
            )
        if dataframe[FIXTURE_ID_COLUMN].isna().any():
            raise ValueError(
                f"Feature table '{qualified_table_name}' contains null "
                f"{FIXTURE_ID_COLUMN} values"
            )
        if dataframe[FIXTURE_ID_COLUMN].duplicated().any():
            raise ValueError(
                f"Feature table '{qualified_table_name}' contains duplicate "
                f"{FIXTURE_ID_COLUMN} values"
            )

    def download_feature_tables(self) -> dict[str, pd.DataFrame]:
        """Download source tables separately and remove duplicate features."""
        feature_tables, key_features, schema, _, _ = self._validated_settings()
        connector = self.etl_helper.database_connection
        downloaded: dict[str, pd.DataFrame] = {}
        source_dtypes: dict[str, dict[str, Any]] = {}
        occupied_columns: set[str] = set()
        key_feature_set = set(key_features)

        for table_alias, table_name in feature_tables.items():
            dataframe = self._download_table(table_name, schema)
            self._validate_fixture_ids(dataframe, f"{schema}.{table_name}")
            reflected_columns = connector.get_table_columns(
                self._unqualified_table_name(table_name, schema),
                schema=schema,
            )
            reflected_dtypes = {
                column["name"]: column["type"] for column in reflected_columns
            }
            missing_types = set(dataframe.columns).difference(reflected_dtypes)
            if missing_types:
                raise ValueError(
                    f"Could not reflect source types for '{table_alias}': "
                    + ", ".join(sorted(missing_types))
                )

            if table_alias == BASE_TABLE_ALIAS:
                if dataframe.empty:
                    raise ValueError("The base feature table must not be empty")
                if DATE_COLUMN not in dataframe.columns:
                    raise ValueError(
                        f"Base feature table '{schema}.{table_name}' has no "
                        f"'{DATE_COLUMN}' column"
                    )
                downloaded[table_alias] = dataframe
                source_dtypes[table_alias] = {
                    column: reflected_dtypes[column]
                    for column in dataframe.columns
                }
                occupied_columns.update(dataframe.columns)
                continue

            feature_columns = [
                column
                for column in dataframe.columns
                if column != FIXTURE_ID_COLUMN and column not in key_feature_set
            ]
            overlapping_columns = set(feature_columns).intersection(occupied_columns)
            if overlapping_columns:
                overlap = ", ".join(sorted(overlapping_columns))
                self.etl_helper.logger.log_event(
                    "INFO",
                    f"Ignoring overlapping features from '{schema}.{table_name}': "
                    f"{overlap}",
                )
                feature_columns = [
                    column
                    for column in feature_columns
                    if column not in overlapping_columns
                ]

            downloaded[table_alias] = dataframe.loc[
                :, [FIXTURE_ID_COLUMN, *feature_columns]
            ].copy()
            source_dtypes[table_alias] = {
                column: reflected_dtypes[column]
                for column in downloaded[table_alias].columns
            }
            occupied_columns.update(feature_columns)

        self.params["feature_table_dtypes"] = source_dtypes
        return downloaded

    def download_and_join_feature_tables(
        self,
        feature_tables: Mapping[str, str] | None = None,
    ) -> pd.DataFrame:
        """Download and join a set of feature tables by fixture ID.

        Source tables are used when ``feature_tables`` is omitted. This method
        remains available when persisted feature tables need to be loaded in a
        later process; the active imputation run joins its DataFrames directly.
        """
        configured_tables, _, schema, _, _ = self._validated_settings()
        tables_to_join = feature_tables or configured_tables
        if not isinstance(tables_to_join, Mapping) or not tables_to_join:
            raise ValueError("feature_tables must be a non-empty mapping")
        if BASE_TABLE_ALIAS not in tables_to_join:
            raise ValueError(
                f"feature_tables must contain a '{BASE_TABLE_ALIAS}' alias"
            )

        downloaded_tables = {
            table_alias: self._download_table(table_name, schema)
            for table_alias, table_name in tables_to_join.items()
        }
        return self.join_feature_tables(downloaded_tables)

    def join_feature_tables(
        self,
        feature_tables: Mapping[str, pd.DataFrame],
    ) -> pd.DataFrame:
        """Join already-loaded feature DataFrames without database round trips."""
        _, key_features, _, _, _ = self._validated_settings()
        if not isinstance(feature_tables, Mapping) or not feature_tables:
            raise ValueError("feature_tables must be a non-empty mapping")
        if BASE_TABLE_ALIAS not in feature_tables:
            raise ValueError(
                f"feature_tables must contain a '{BASE_TABLE_ALIAS}' alias"
            )

        key_feature_set = set(key_features)
        base_dataframe = feature_tables[BASE_TABLE_ALIAS]
        if not isinstance(base_dataframe, pd.DataFrame):
            raise TypeError(
                f"Feature table '{BASE_TABLE_ALIAS}' must be a DataFrame"
            )
        self._validate_fixture_ids(base_dataframe, BASE_TABLE_ALIAS)
        joined_dataframe = base_dataframe.copy()

        for table_alias, feature_dataframe in feature_tables.items():
            if table_alias == BASE_TABLE_ALIAS:
                continue

            if not isinstance(feature_dataframe, pd.DataFrame):
                raise TypeError(f"Feature table '{table_alias}' must be a DataFrame")
            self._validate_fixture_ids(feature_dataframe, table_alias)
            feature_columns = [
                column
                for column in feature_dataframe.columns
                if column != FIXTURE_ID_COLUMN and column not in key_feature_set
            ]
            overlapping_columns = set(feature_columns).intersection(
                joined_dataframe.columns
            )
            if overlapping_columns:
                overlap = ", ".join(sorted(overlapping_columns))
                self.etl_helper.logger.log_event(
                    "INFO",
                    f"Ignoring overlapping features from '{table_alias}': {overlap}",
                )
                feature_columns = [
                    column
                    for column in feature_columns
                    if column not in overlapping_columns
                ]

            joined_dataframe = joined_dataframe.merge(
                feature_dataframe.loc[:, [FIXTURE_ID_COLUMN, *feature_columns]],
                how="left",
                on=FIXTURE_ID_COLUMN,
                sort=False,
                validate="one_to_one",
            )

        return joined_dataframe

    def split_datasets(self, dataframe: pd.DataFrame) -> dict[str, pd.DataFrame]:
        """Split base rows using the configured inclusive calendar dates."""
        if not isinstance(dataframe, pd.DataFrame):
            raise TypeError("dataframe must be a pandas DataFrame")
        if DATE_COLUMN not in dataframe.columns:
            raise ValueError(f"dataframe must contain a '{DATE_COLUMN}' column")

        segments = self._date_segments()
        try:
            normalized_dates = pd.to_datetime(
                dataframe[DATE_COLUMN],
                errors="raise",
                format="mixed",
                utc=True,
            ).dt.tz_localize(None).dt.normalize()
        except (TypeError, ValueError) as exc:
            raise ValueError(f"'{DATE_COLUMN}' contains invalid dates") from exc

        datasets: dict[str, pd.DataFrame] = {}
        assigned_rows = pd.Series(False, index=dataframe.index)
        for dataset_name in DATASET_NAMES:
            start, end = segments[dataset_name]
            row_mask = normalized_dates.between(start, end, inclusive="both")
            assigned_rows |= row_mask
            datasets[dataset_name] = dataframe.loc[row_mask].copy()

        if datasets["train"].empty:
            raise ValueError("The configured train date range contains no rows")

        unassigned_count = int((~assigned_rows).sum())
        if unassigned_count:
            self.etl_helper.logger.log_event(
                "INFO",
                "Rows outside configured dataset date ranges were ignored: "
                f"{unassigned_count}",
            )

        return datasets

    def split_feature_tables(
        self,
        feature_tables: Mapping[str, pd.DataFrame],
    ) -> dict[str, dict[str, pd.DataFrame]]:
        """Create aligned per-source tables for each configured dataset."""
        if BASE_TABLE_ALIAS not in feature_tables:
            raise ValueError(
                f"feature_tables must contain a '{BASE_TABLE_ALIAS}' DataFrame"
            )

        base_splits = self.split_datasets(feature_tables[BASE_TABLE_ALIAS])
        split_tables: dict[str, dict[str, pd.DataFrame]] = {}
        for dataset_name, base_dataset in base_splits.items():
            dataset_tables = {BASE_TABLE_ALIAS: base_dataset}
            fixture_ids = base_dataset.loc[:, [FIXTURE_ID_COLUMN]]

            for table_alias, feature_dataframe in feature_tables.items():
                if table_alias == BASE_TABLE_ALIAS:
                    continue
                # Reindex every source table to the base fixtures before fitting
                # or transforming, so a wholly absent source row is imputed too.
                dataset_tables[table_alias] = fixture_ids.merge(
                    feature_dataframe,
                    how="left",
                    on=FIXTURE_ID_COLUMN,
                    sort=False,
                    validate="one_to_one",
                )

            split_tables[dataset_name] = dataset_tables

        return split_tables

    def calculate_imputation_values(
        self,
        train_dataset: pd.DataFrame,
        features: list[str],
    ) -> dict[str, Any]:
        """Return train-fitted values; override this for another strategy."""

        return {feature: 0 for feature in features}

    def fit_imputation_metadata(
        self,
        train_tables: Mapping[str, pd.DataFrame],
    ) -> pd.DataFrame:
        """Fit per-table feature eligibility and values using train rows only."""
        _, key_features, _, _, imputation_filter = self._validated_settings()
        if not isinstance(train_tables, Mapping) or not train_tables:
            raise ValueError("train_tables must be a non-empty mapping")

        key_feature_set = set(key_features)
        maximum_percentage = imputation_filter * 100.0
        metadata_frames: list[pd.DataFrame] = []
        values_by_table: dict[str, dict[str, Any]] = {}
        excluded_by_table: dict[str, list[str]] = {}
        train_start, train_end = self._date_segments()["train"]

        for table_alias, train_dataset in train_tables.items():
            if not isinstance(train_dataset, pd.DataFrame):
                raise TypeError(f"Train table '{table_alias}' must be a DataFrame")
            if train_dataset.empty:
                raise ValueError(f"Train table '{table_alias}' must not be empty")

            candidate_features = [
                column
                for column in train_dataset.columns
                if column not in key_feature_set
            ]
            total_rows = len(train_dataset)
            metadata = pd.DataFrame(
                {
                    "feature_table": table_alias,
                    "feature": candidate_features,
                    "missing_rows": [
                        int(train_dataset[column].isna().sum())
                        for column in candidate_features
                    ],
                    "total_rows": total_rows,
                }
            )
            metadata["imputation_percentage"] = (
                metadata["missing_rows"] / total_rows * 100.0
            )
            metadata["passes_imputation_filter"] = (
                metadata["imputation_percentage"] <= maximum_percentage
            )
            retained_features = metadata.loc[
                metadata["passes_imputation_filter"], "feature"
            ].tolist()
            excluded_features = metadata.loc[
                ~metadata["passes_imputation_filter"], "feature"
            ].tolist()
            imputation_values = self.calculate_imputation_values(
                train_dataset,
                retained_features,
            )
            if set(imputation_values) != set(retained_features):
                raise ValueError(
                    "The fitted imputation values must contain exactly the "
                    f"retained train features for '{table_alias}'"
                )

            metadata["imputation_strategy"] = self.params.get(
                "imputation_strategy",
                "constant_zero",
            )
            metadata["imputation_value"] = metadata["feature"].map(
                imputation_values
            )
            metadata["fitted_on_dataset"] = "train"
            metadata["fit_start_date"] = train_start.date().isoformat()
            metadata["fit_end_date"] = train_end.date().isoformat()
            metadata_frames.append(metadata)
            values_by_table[table_alias] = imputation_values
            excluded_by_table[table_alias] = excluded_features

        combined_metadata = pd.concat(metadata_frames, ignore_index=True)
        self.params["imputation_values"] = values_by_table
        self.params["imputation_metadata"] = combined_metadata
        self.params["imputation_excluded_features"] = list(
            dict.fromkeys(
                feature
                for features in excluded_by_table.values()
                for feature in features
            )
        )
        return combined_metadata

    def apply_imputation_to_splits(
        self,
        split_tables: Mapping[str, Mapping[str, pd.DataFrame]],
    ) -> dict[str, dict[str, pd.DataFrame]]:
        """Apply each source table's train-fitted values to every split."""
        _, key_features, _, _, _ = self._validated_settings()
        values_by_table = self.params.get("imputation_values")
        if not isinstance(values_by_table, dict):
            raise RuntimeError("fit_imputation_metadata must run first")

        transformed: dict[str, dict[str, pd.DataFrame]] = {}
        for dataset_name in DATASET_NAMES:
            if dataset_name not in split_tables:
                raise ValueError(f"split_tables is missing '{dataset_name}'")
            transformed[dataset_name] = {}

            for table_alias, imputation_values in values_by_table.items():
                if table_alias not in split_tables[dataset_name]:
                    raise ValueError(
                        f"{dataset_name} is missing feature table '{table_alias}'"
                    )
                dataset = split_tables[dataset_name][table_alias]
                feature_columns = list(imputation_values)
                selected_columns = [
                    column
                    for column in dataset.columns
                    if column in key_features or column in imputation_values
                ]
                missing_features = set(feature_columns).difference(selected_columns)
                if missing_features:
                    raise ValueError(
                        f"{dataset_name}.{table_alias} is missing fitted features: "
                        + ", ".join(sorted(missing_features))
                    )

                imputed_table = dataset.loc[:, selected_columns].copy()
                imputed_table.loc[:, feature_columns] = (
                    imputed_table.loc[:, feature_columns].fillna(imputation_values)
                )
                transformed[dataset_name][table_alias] = imputed_table

        return transformed

    def save_imputation_outputs_to_db(
        self,
        metadata: pd.DataFrame,
        imputed_feature_tables: Mapping[str, Mapping[str, pd.DataFrame]],
    ) -> dict[str, dict[str, str]]:
        """Replace metadata and every dataset/source imputed table."""
        feature_tables, _, schema, metadata_table, _ = self._validated_settings()
        connector = self.etl_helper.database_connection
        source_dtypes = self.params.get("feature_table_dtypes")
        if not isinstance(source_dtypes, Mapping):
            raise RuntimeError("download_feature_tables must run before persistence")
        table_prefix = self.params.get("imputed_table_prefix", "imputed_zero")
        if not isinstance(table_prefix, str) or not table_prefix:
            raise ValueError("imputed_table_prefix must be a non-empty string")

        connector.upload_dataframe(
            metadata,
            metadata_table,
            if_exists="replace",
            index=False,
            schema=schema,
        )

        qualified_tables: dict[str, dict[str, str]] = {}
        for dataset_name in DATASET_NAMES:
            qualified_tables[dataset_name] = {}
            for table_alias in feature_tables:
                table_name = f"{table_prefix}_{dataset_name}_{table_alias}"
                imputed_table = imputed_feature_tables[dataset_name][table_alias]
                table_dtypes = source_dtypes.get(table_alias)
                if not isinstance(table_dtypes, Mapping):
                    raise ValueError(
                        f"Source SQL types are missing for '{table_alias}'"
                    )
                missing_types = set(imputed_table.columns).difference(table_dtypes)
                if missing_types:
                    raise ValueError(
                        f"Source SQL types are missing for '{table_alias}': "
                        + ", ".join(sorted(missing_types))
                    )
                connector.upload_dataframe(
                    imputed_table,
                    table_name,
                    if_exists="replace",
                    index=False,
                    schema=schema,
                    dtype={
                        column: table_dtypes[column]
                        for column in imputed_table.columns
                    },
                    method=None,
                )
                qualified_tables[dataset_name][table_alias] = (
                    f"{schema}.{table_name}"
                )

        self.params["imputed_tables"] = qualified_tables
        self.params["imputation_metadata_table"] = f"{schema}.{metadata_table}"
        return qualified_tables

    def download_and_join_imputed_tables(self) -> pd.DataFrame:
        """Persist split tables and retain one joined dataset per split."""
        try:
            source_tables = self.download_feature_tables()
            split_tables = self.split_feature_tables(source_tables)
            metadata = self.fit_imputation_metadata(split_tables["train"])
            imputed_feature_tables = self.apply_imputation_to_splits(split_tables)
            self.save_imputation_outputs_to_db(metadata, imputed_feature_tables)

            joined_datasets = {
                dataset_name: self.join_feature_tables(
                    imputed_feature_tables[dataset_name]
                )
                for dataset_name in DATASET_NAMES
            }
            # Feature selection consumes train; later training/evaluation steps
            # consume val, test, and OOT from this same payload mapping.
            self.params["imputed_datasets"] = joined_datasets
            return joined_datasets["train"]
        finally:
            # Reflected types are required only while creating output tables.
            self.params.pop("feature_table_dtypes", None)

    def create_zero_imputed_tables(self) -> dict[str, dict[str, str]]:
        """Build and return all per-dataset, per-source imputed tables."""
        self.download_and_join_imputed_tables()
        return self.params["imputed_tables"]

    def run(self) -> dict[str, Any]:
        """Fit on train and create metadata plus per-source split tables."""
        self.etl_helper.logger.log_event("INFO", "Feature imputation started")

        try:
            self.download_and_join_imputed_tables()
            result = {
                "imputed_tables": self.params["imputed_tables"],
                "imputed_datasets": self.params["imputed_datasets"],
                "imputation_values": self.params["imputation_values"],
                "imputation_metadata": self.params["imputation_metadata"],
                "imputation_excluded_features": self.params[
                    "imputation_excluded_features"
                ],
                "imputation_metadata_table": self.params[
                    "imputation_metadata_table"
                ],
            }
            table_count = sum(
                len(tables) for tables in self.params["imputed_tables"].values()
            )
            fitted_feature_count = sum(
                len(values) for values in self.params["imputation_values"].values()
            )
            self.etl_helper.logger.log_event(
                "INFO",
                "Feature imputation completed "
                f"| tables={table_count} "
                f"| fitted_features={fitted_feature_count}",
            )
            self.etl_helper.set_payload(result)
            return result
        except Exception as exc:
            self.etl_helper.logger.log_event(
                "ERROR",
                f"Feature imputation failed: {exc}",
            )
            raise
