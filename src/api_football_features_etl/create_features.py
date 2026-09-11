"""Create database features by executing the configured SQL scripts."""

from pathlib import Path

from .ETLHelper import ETLHelper


class CreateFeatures:
    """Discover and execute feature-engineering SQL files in name order."""

    def __init__(self, etl_helper: ETLHelper) -> None:
        """Configure the step with shared ETL resources.

        Parameters:
            etl_helper: Shared, initialized database, logger, and configuration.
        """
        if not isinstance(etl_helper, ETLHelper):
            raise TypeError("etl_helper must be an initialized ETLHelper")

        self.etl_helper = etl_helper
        self.params = etl_helper.params.get("CreateFeatures", {})
        self.params.update(etl_helper.params.get("Global", {}))

    def run(self) -> list[Path]:
        """Execute the SQL files listed in ``CreateFeatures.files`` in order."""
        self.etl_helper.logger.log_event("INFO", "SQL feature execution started")

        try:
            configured_files = self.params.get("files")
            if not isinstance(configured_files, list) or not configured_files:
                raise ValueError("CreateFeatures.files must be a non-empty list")

            sql_dir = self.etl_helper.DEFAULT_SQL_DIR / "feature_creation"
            if not sql_dir.is_dir():
                raise NotADirectoryError(f"SQL directory not found: {sql_dir}")

            sql_files: list[Path] = []
            for file_name in configured_files:
                if (
                    not isinstance(file_name, str)
                    or not file_name
                    or Path(file_name).name != file_name
                    or Path(file_name).suffix.lower() != ".sql"
                ):
                    raise ValueError(
                        "Each CreateFeatures.files entry must be a .sql filename"
                    )

                sql_file = sql_dir / file_name
                if not sql_file.is_file():
                    raise FileNotFoundError(f"SQL file not found: {sql_file}")
                sql_files.append(sql_file)

            self.etl_helper.logger.log_event(
                "INFO",
                f"Found {len(sql_files)} configured SQL file(s) in {sql_dir}",
            )

            completed_files: list[Path] = []
            for sql_file in sql_files:
                self.etl_helper.logger.log_event(
                    "INFO",
                    f"Starting SQL file: {sql_file.name}",
                )
                self.etl_helper.database_connection.run_sql_file(
                    sql_file,
                    params=self.params,
                )
                completed_files.append(sql_file)

            self.etl_helper.logger.log_event(
                "INFO",
                "SQL feature execution completed: "
                f"{len(completed_files)} file(s)",
            )
            return completed_files
        except Exception as exc:
            self.etl_helper.logger.log_event(
                "ERROR",
                f"SQL feature execution failed: {exc}",
            )
            raise
