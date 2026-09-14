"""Feature-imputation operations executed in PostgreSQL and pandas."""

from typing import Any, Mapping

import pandas as pd
from sqlalchemy import Integer, Numeric

from .ETLHelper import ETLHelper


QUERY_ZERO_IMPUTE_PATH = "feature_selection/imputed_table_sql_template.sql"



class FeatureImputation:
    """Create imputation tables, metadata, and a filtered training dataset."""

    def __init__(self, etl_helper: ETLHelper) -> None:
        """Initialize the step with shared resources and configuration."""
        if not isinstance(etl_helper, ETLHelper):
            raise TypeError("etl_helper must be an initialized ETLHelper")

        self.etl_helper = etl_helper
        self.params = etl_helper.params.get("FeatureImputation", {})
        self.params.update(etl_helper.params.get("Global", {}))
        self.params["sql_files"] = {
            "zero_impute": self.etl_helper.sql_path / QUERY_ZERO_IMPUTE_PATH
        }

    def _build_zero_imputed_columns(
        self,
        table_name: str,
        key_features: list[str],
        schema: str,
    ) -> str:
        """Return a typed SQL projection that zero-imputes non-key columns."""
        connector = self.etl_helper.database_connection
        columns = connector.get_table_columns(table_name, schema=schema)
        if not columns:
            raise ValueError(f"Feature table '{schema}.{table_name}' has no columns")

        key_feature_set = set(key_features)
        column_expressions: list[str] = []

        for column in columns:
            column_name = column["name"]
            column_type = column["type"]

            if column_name in key_feature_set:
                column_expressions.append(column_name)
                continue

            if not isinstance(column_type, (Integer, Numeric)):
                raise TypeError(
                    "Zero imputation requires numeric non-key columns; "
                    f"'{column_name}' has type {column_type}"
                )

            compiled_type = connector.compile_sql_type(column_type)
            column_expressions.append(
                f"COALESCE({column_name}, CAST(0 AS {compiled_type})) "
                f"AS {column_name}"
            )

        return ",\n    ".join(column_expressions)

    def create_zero_imputed_tables(self) -> dict[str, str]:
        """Create all configured imputed tables directly in PostgreSQL."""
        feature_tables = self.params.get("feature_tables")
        key_features = self.params.get("key_features")
        schema = self.params.get("schema", "public")

        if not isinstance(feature_tables, Mapping) or not feature_tables:
            raise ValueError("feature_tables must be a non-empty configuration object")
        if not isinstance(key_features, list) or not all(
            isinstance(column, str) for column in key_features
        ):
            raise ValueError("key_features must be a list of column names")
        if not isinstance(schema, str) or not schema:
            raise ValueError("schema must be a non-empty string")

        connector = self.etl_helper.database_connection

        created_tables: dict[str, str] = {}

        try:
            for table_alias, source_table_name in feature_tables.items():
                if not isinstance(table_alias, str) or not table_alias:
                    raise ValueError("Feature table aliases must be non-empty strings")
                if not isinstance(source_table_name, str) or not source_table_name:
                    raise ValueError(
                        f"Feature table '{table_alias}' must have a non-empty name"
                    )

                target_table_name = f"imputed_zero_{table_alias}"
                columns = self._build_zero_imputed_columns(
                    source_table_name,
                    key_features,
                    schema,
                )
                connector.run_sql_file(
                    self.params["sql_files"]["zero_impute"],
                    template_values={
                        "columns": columns,
                        "source_table": f"{schema}.{source_table_name}",
                        "target_table": f"{schema}.{target_table_name}"
                    },
                )
                created_tables[table_alias] = f"{schema}.{target_table_name}"

            self.etl_helper.logger.log_event(
                "INFO",
                f"Created {len(created_tables)} zero-imputed feature table(s)",
            )
            return created_tables
        except Exception as exc:
            self.etl_helper.logger.log_event(
                "ERROR",
                f"SQL zero imputation failed: {exc}",
            )
            raise

    def download_and_join_imputed_tables(self) -> pd.DataFrame:
        """Join source tables, filter sparse features, and zero-impute them.

        The league-features table contributes all columns. Other tables use
        ``fixture_id`` only as the join key and contribute only columns that
        are not configured as key features.
        """
        feature_tables = self.params.get("feature_tables")
        key_features = self.params.get("key_features")
        schema = self.params.get("schema", "public")

        if not isinstance(feature_tables, Mapping) or not feature_tables:
            raise ValueError("feature_tables must be a non-empty configuration object")
        if "league_features" not in feature_tables:
            raise ValueError("feature_tables must contain a 'league_features' alias")
        if not isinstance(key_features, list) or not all(
            isinstance(column, str) for column in key_features
        ):
            raise ValueError("key_features must be a list of column names")
        if not isinstance(schema, str) or not schema:
            raise ValueError("schema must be a non-empty string")

        connector = self.etl_helper.database_connection
        fixture_id = "fixture_id"
        key_feature_set = set(key_features)
        league_table_name = feature_tables["league_features"]
        joined_dataframe = connector.download_table(
            league_table_name,
            schema=schema,
        )

        if fixture_id not in joined_dataframe.columns:
            raise ValueError(
                f"Base table '{schema}.{league_table_name}' has no fixture_id column"
            )
        if joined_dataframe[fixture_id].duplicated().any():
            raise ValueError(
                f"Base table '{schema}.{league_table_name}' contains duplicate "
                "fixture_id values"
            )

        for table_alias in feature_tables:
            if table_alias == "league_features":
                continue

            table_name = feature_tables[table_alias]
            feature_dataframe = connector.download_table(
                table_name,
                schema=schema,
            )
            if fixture_id not in feature_dataframe.columns:
                raise ValueError(
                    f"Feature table '{schema}.{table_name}' has no fixture_id column"
                )
            if feature_dataframe[fixture_id].duplicated().any():
                raise ValueError(
                    f"Feature table '{schema}.{table_name}' contains duplicate "
                    "fixture_id values"
                )

            feature_columns = [
                column
                for column in feature_dataframe.columns
                if column != fixture_id and column not in key_feature_set
            ]
            overlapping_columns = set(feature_columns).intersection(
                joined_dataframe.columns
            )
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

            joined_dataframe = joined_dataframe.merge(
                feature_dataframe.loc[:, [fixture_id, *feature_columns]],
                how="left",
                on=fixture_id,
                sort=False,
                validate="one_to_one",
            )

        if joined_dataframe.empty:
            raise ValueError("The joined feature dataset must not be empty")

        imputation_percentage_table = self.params.get("imputation_percentage_tbl")
        imputation_percentage_filter = self.params.get(
            "imputation_percentage_filter"
        )
        if (
            not isinstance(imputation_percentage_table, str)
            or not imputation_percentage_table
        ):
            raise ValueError(
                "imputation_percentage_tbl must be a non-empty table name"
            )
        if not isinstance(imputation_percentage_filter, (int, float)) or isinstance(
            imputation_percentage_filter, bool
        ):
            raise TypeError("imputation_percentage_filter must be numeric")
        imputation_percentage_filter = float(imputation_percentage_filter)
        if not 0 <= imputation_percentage_filter <= 1:
            raise ValueError(
                "imputation_percentage_filter must be between 0 and 1"
            )

        candidate_features = [
            column
            for column in joined_dataframe.columns
            if column not in key_feature_set
        ]
        total_rows = len(joined_dataframe)
        imputation_metadata = pd.DataFrame(
            {
                "feature": candidate_features,
                "missing_rows": [
                    int(joined_dataframe[column].isna().sum())
                    for column in candidate_features
                ],
                "total_rows": total_rows,
            }
        )
        imputation_metadata["imputation_percentage"] = (
            imputation_metadata["missing_rows"] / total_rows * 100.0
        )
        maximum_imputation_percentage = imputation_percentage_filter * 100.0
        imputation_metadata["passes_imputation_filter"] = (
            imputation_metadata["imputation_percentage"]
            <= maximum_imputation_percentage
        )
        connector.upload_dataframe(
            imputation_metadata,
            imputation_percentage_table,
            if_exists="replace",
            index=False,
            schema=schema,
        )

        # no imputation filtering
        # columns_to_impute = imputation_metadata["feature"].tolist()
        # excluded_features = []
        # selected_columns = [
        #     column
        #     for column in joined_dataframe.columns
        #     if column in key_feature_set or column in columns_to_impute
        # ]

        # imputation filtering
        columns_to_impute = imputation_metadata.loc[
            imputation_metadata["passes_imputation_filter"], "feature"
        ].tolist()
        excluded_features = imputation_metadata.loc[
            ~imputation_metadata["passes_imputation_filter"], "feature"
        ].tolist()
        selected_columns = [
            column
            for column in joined_dataframe.columns
            if column in key_feature_set or column in columns_to_impute
        ]

        # Keep imputation separate so its strategy can later be replaced
        # without changing the join, metadata, or filtering logic.
        zero_imputed_train_set = joined_dataframe.loc[:, selected_columns].copy()
        zero_imputed_train_set.loc[:, columns_to_impute] = (
            zero_imputed_train_set.loc[:, columns_to_impute].fillna(0)
        )
        self.params["zero_imputed_train_set"] = zero_imputed_train_set
        self.params["imputation_metadata"] = imputation_metadata
        self.params["imputation_excluded_features"] = excluded_features

        self.etl_helper.logger.log_event(
            "INFO",
            "Imputation metadata created "
            f"| table={schema}.{imputation_percentage_table} "
            f"| filter={maximum_imputation_percentage:.2f}% "
            f"| retained={len(columns_to_impute)} "
            f"| excluded={len(excluded_features)}",
        )

        self.etl_helper.logger.log_event("INFO", "0 imputed train set:\n")
        self.etl_helper.logger.log_event(
            "INFO",
            self.params["zero_imputed_train_set"].head().to_string(),
        )
        self.etl_helper.logger.log_event(
            "INFO",
            "Joined zero-imputed feature tables "
            f"| rows={len(zero_imputed_train_set)} "
            f"| columns={len(zero_imputed_train_set.columns)}",
        )
        return zero_imputed_train_set

    def run(self) -> dict[str, Any]:
        """Create and join the configured zero-imputed feature tables."""
        self.etl_helper.logger.log_event("INFO", "Feature imputation started")

        try:
            imputed_tables = self.create_zero_imputed_tables()
            joined_features = self.download_and_join_imputed_tables()
            result = {
                "imputed_tables": imputed_tables,
                "imputed_dataset": joined_features,
                "imputation_metadata": self.params["imputation_metadata"],
                "imputation_excluded_features": self.params[
                    "imputation_excluded_features"
                ],
                "imputation_metadata_table": (
                    f"{self.params.get('schema', 'public')}."
                    f"{self.params['imputation_percentage_tbl']}"
                ),
            }
            self.etl_helper.logger.log_event(
                "INFO",
                f"Feature imputation completed for {len(imputed_tables)} table(s)",
            )

            self.etl_helper.set_payload(result)

            return result
        except Exception as exc:
            self.etl_helper.logger.log_event(
                "ERROR",
                f"Feature imputation failed: {exc}",
            )
            raise
