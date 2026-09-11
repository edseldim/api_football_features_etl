import os
from pathlib import Path
from typing import Any, Callable, Mapping, Optional, Union

import dotenv
import pandas as pd
import sqlparse
from sqlalchemy import create_engine, inspect, text
from sqlalchemy.engine import Engine


dotenv.load_dotenv()


class PostgresConnector:
    """Connect to a PostgreSQL database and upload pandas DataFrames."""

    def __init__(
        self,
        database_url: Optional[str] = None,
        env_path: Optional[Union[str, Path]] = None,
        echo: bool = False,
        log_event: Optional[Callable[[str, Any], None]] = None,
    ):
        """Create a database connector using the .env connection string.

        Parameters:
            database_url (str | None): Optional database connection URL. If not provided,
                the connector will read DATABASE_URL from the environment.
            env_path (str | Path | None): Optional path to a .env file to load.
            echo (bool): When True, SQLAlchemy will log SQL statements.
            log_event (callable | None): Optional callback receiving ``level`` and
                ``message`` for connector log events.
        """
        self._log_event = log_event or self._default_log_event

        try:
            if env_path is not None:
                dotenv.load_dotenv(dotenv_path=str(env_path))

            self.database_url = database_url or os.getenv("DATABASE_URL")
            if not self.database_url:
                raise ValueError("DATABASE_URL must be set either via argument or in the environment")

            self.engine: Engine = create_engine(self.database_url, echo=echo)
            self._log_event("INFO", "PostgreSQL connector initialized")
        except Exception as exc:
            self._log_event("ERROR", f"PostgreSQL connector initialization failed: {exc}")
            raise

    @staticmethod
    def _default_log_event(level, message):
        """Provide safe terminal logging when the connector is used independently.

        Parameters:
            level (str): Log severity such as ``INFO`` or ``ERROR``.
            message (Any): Message or value to print.
        """
        print(f"[{str(level).upper()}] {message}")

    def _log_database_operation(
        self,
        operation: str,
        status: str,
        target: str,
        *,
        level: str = "INFO",
        **details: Any,
    ) -> None:
        """Log database operations using one consistent message format."""
        fields = [
            f"operation={operation}",
            f"status={status}",
            f"target={target}",
        ]
        fields.extend(f"{key}={value}" for key, value in details.items())
        self._log_event(level, " | ".join(fields))

    @staticmethod
    def _format_database_error(exc: Exception) -> str:
        """Return the useful error message without SQLAlchemy's full SQL dump."""
        return str(exc).split("\n[SQL:", maxsplit=1)[0].strip()

    def upload_dataframe(
        self,
        df: pd.DataFrame,
        table_name: str,
        if_exists: str = "append",
        index: bool = False,
        schema: Optional[str] = None,
        dtype: Optional[dict] = None,
        method: Optional[str] = "multi",
    ) -> None:
        """Upload a pandas DataFrame to a PostgreSQL table.

        Parameters:
            df (pandas.DataFrame): DataFrame to upload.
            table_name (str): Destination table name.
            if_exists (str): Behavior if the table already exists: 'fail', 'replace', or 'append'.
            index (bool): Whether to write DataFrame index as a column.
            schema (str | None): Optional database schema to use.
            dtype (dict | None): Optional column dtype mapping for SQLAlchemy.
            method (str | None): Method used by pandas to_sql. Use 'multi' for batch inserts.

        Raises:
            TypeError: If df is not a pandas DataFrame.
            ValueError: If table_name is empty or invalid.
        """
        try:
            if not isinstance(df, pd.DataFrame):
                raise TypeError("df must be a pandas DataFrame")
            if not table_name or not isinstance(table_name, str):
                raise ValueError("table_name must be a non-empty string")

            target = f"{schema}.{table_name}" if schema else table_name
            self._log_database_operation(
                "upload_dataframe",
                "started",
                target,
                rows=len(df),
            )
            df.to_sql(
                name=table_name,
                con=self.engine,
                if_exists=if_exists,
                index=index,
                schema=schema,
                dtype=dtype,
                method=method,
            )
            self._log_database_operation(
                "upload_dataframe",
                "succeeded",
                target,
                rows=len(df),
            )
        except Exception as exc:
            target = (
                f"{schema}.{table_name}"
                if schema and isinstance(table_name, str)
                else str(table_name)
            )
            self._log_database_operation(
                "upload_dataframe",
                "failed",
                target,
                level="ERROR",
                error=self._format_database_error(exc),
            )
            raise

    def download_dataframe(
        self,
        file_path: Union[str, Path],
        params: Optional[Mapping[str, Any]] = None,
    ) -> pd.DataFrame:
        """Execute a query from a SQL file and return its rows as a DataFrame.

        SQL values should use SQLAlchemy named parameters, for example
        ``WHERE table_name = :table_name``.

        Parameters:
            file_path: Path to a ``.sql`` file containing one query.
            params: Optional values for the query's named parameters.

        Returns:
            pandas.DataFrame: Query results, including column names.

        Raises:
            TypeError: If ``file_path`` or ``params`` has an invalid type.
            ValueError: If the path is empty, is not a ``.sql`` file, or the
                file does not contain exactly one SQL statement.
            FileNotFoundError: If the SQL file does not exist.
        """
        if not isinstance(file_path, (str, Path)):
            raise TypeError("file_path must be a string or Path")
        if params is not None and not isinstance(params, Mapping):
            raise TypeError("params must be a mapping or None")

        file_path_text = str(file_path)
        if not file_path_text:
            raise ValueError("file_path must not be empty")

        sql_path = Path(file_path_text).expanduser()
        if sql_path.suffix.lower() != ".sql":
            raise ValueError("file_path must have a .sql extension")

        try:
            if not sql_path.is_file():
                raise FileNotFoundError(f"SQL file not found: {sql_path}")

            sql = sql_path.read_text(encoding="utf-8")
            queries = [query.strip() for query in sqlparse.split(sql) if query.strip()]
            if len(queries) != 1:
                raise ValueError(
                    "download_dataframe requires exactly one SQL statement; "
                    f"found {len(queries)}"
                )

            bound_params = dict(params or {})
            self._log_database_operation(
                "download_dataframe",
                "started",
                sql_path.name,
            )

            with self.engine.connect() as connection:
                dataframe = pd.read_sql_query(
                    text(queries[0]),
                    connection,
                    params=bound_params,
                )

            self._log_database_operation(
                "download_dataframe",
                "succeeded",
                sql_path.name,
                rows=len(dataframe),
                columns=len(dataframe.columns),
            )
            return dataframe
        except Exception as exc:
            self._log_database_operation(
                "download_dataframe",
                "failed",
                str(sql_path),
                level="ERROR",
                error=self._format_database_error(exc),
            )
            raise

    def download_table(
        self,
        table_name: str,
        schema: Optional[str] = None,
    ) -> pd.DataFrame:
        """Download a database table into a pandas DataFrame."""
        if not isinstance(table_name, str) or not table_name:
            raise ValueError("table_name must be a non-empty string")
        if schema is not None and (not isinstance(schema, str) or not schema):
            raise ValueError("schema must be a non-empty string or None")

        target = f"{schema}.{table_name}" if schema else table_name
        try:
            self._log_database_operation("download_table", "started", target)
            with self.engine.connect() as connection:
                dataframe = pd.read_sql_table(
                    table_name,
                    connection,
                    schema=schema,
                )
            self._log_database_operation(
                "download_table",
                "succeeded",
                target,
                rows=len(dataframe),
                columns=len(dataframe.columns),
            )
            return dataframe
        except Exception as exc:
            self._log_database_operation(
                "download_table",
                "failed",
                target,
                level="ERROR",
                error=self._format_database_error(exc),
            )
            raise

    def get_table_columns(
        self,
        table_name: str,
        schema: str = "public",
    ) -> list[dict[str, Any]]:
        """Return reflected column metadata for a schema-qualified table."""
        if not isinstance(table_name, str) or not table_name:
            raise ValueError("table_name must be a non-empty string")
        if not isinstance(schema, str) or not schema:
            raise ValueError("schema must be a non-empty string")

        target = f"{schema}.{table_name}"
        try:
            self._log_database_operation("get_table_columns", "started", target)
            columns = inspect(self.engine).get_columns(table_name, schema=schema)
            self._log_database_operation(
                "get_table_columns",
                "succeeded",
                target,
                columns=len(columns),
            )
            return list(columns)
        except Exception as exc:
            self._log_database_operation(
                "get_table_columns",
                "failed",
                target,
                level="ERROR",
                error=self._format_database_error(exc),
            )
            raise

    def quote_identifier(self, identifier: str) -> str:
        """Quote one SQL identifier using the active database dialect."""
        if not isinstance(identifier, str) or not identifier:
            raise ValueError("identifier must be a non-empty string")
        return self.engine.dialect.identifier_preparer.quote(identifier)

    def compile_sql_type(self, column_type: Any) -> str:
        """Compile reflected type metadata for the active database dialect."""
        if column_type is None or not hasattr(column_type, "compile"):
            raise TypeError("column_type must be a SQLAlchemy type")
        return str(column_type.compile(dialect=self.engine.dialect))

    def run_sql_file(
        self,
        file_path: Union[str, Path],
        params: Optional[Mapping[str, Any]] = None,
        template_values: Optional[Mapping[str, str]] = None,
    ) -> None:
        """Execute parameterized statements from an explicitly provided SQL file.

        The file is split into statements with ``sqlparse``. Every statement is
        executed sequentially through SQLAlchemy with the same named parameter
        mapping, for example ``WHERE league_id = :league_id``. All statements
        share one transaction, so failures roll back the complete script. This
        command-only method does not fetch or return result rows.

        Parameters:
            file_path (str | Path): Path to an existing ``.sql`` file.
            params (Mapping[str, Any] | None): Values for named parameters in the
                SQL file. Defaults to an empty mapping.
            template_values (Mapping[str, str] | None): Trusted SQL fragments used
                to fill ``str.format`` placeholders before execution. Identifiers
                must be quoted before they are supplied here.

        Returns:
            None

        Raises:
            TypeError: If ``file_path`` or ``params`` has an invalid type.
            ValueError: If ``file_path`` is empty or does not have a ``.sql`` extension.
            FileNotFoundError: If the requested file does not exist.
        """
        if not isinstance(file_path, (str, Path)):
            raise TypeError("file_path must be a string or Path")

        file_path_text = str(file_path)
        sql_path = Path(file_path_text).expanduser()
        if not file_path_text:
            raise ValueError("file_path must not be empty")
        if sql_path.suffix.lower() != ".sql":
            raise ValueError("file_path must have a .sql extension")
        if params is not None and not isinstance(params, Mapping):
            raise TypeError("params must be a mapping or None")
        if template_values is not None and not isinstance(template_values, Mapping):
            raise TypeError("template_values must be a mapping or None")
        if template_values is not None and not all(
            isinstance(key, str) and isinstance(value, str)
            for key, value in template_values.items()
        ):
            raise TypeError("template_values keys and values must be strings")

        try:
            if not sql_path.is_file():
                raise FileNotFoundError(f"SQL file not found: {sql_path}")

            bound_params = dict(params or {})
            sql = sql_path.read_text(encoding="utf-8")
            if template_values:
                try:
                    sql = sql.format_map(dict(template_values))
                except KeyError as exc:
                    raise ValueError(
                        f"Missing SQL template value: {exc.args[0]}"
                    ) from exc
            queries = [query.strip() for query in sqlparse.split(sql) if query.strip()]
            self._log_database_operation(
                "run_sql_file",
                "started",
                sql_path.name,
                statements=len(queries),
            )

            with self.engine.begin() as connection:
                for statement_number, query in enumerate(queries, start=1):
                    self._log_database_operation(
                        "run_sql_file",
                        "executing",
                        sql_path.name,
                        statement=f"{statement_number}/{len(queries)}",
                        query=query,
                    )
                    connection.execute(text(query), bound_params)

            self._log_database_operation(
                "run_sql_file",
                "succeeded",
                sql_path.name,
                statements=len(queries),
            )
        except Exception as exc:
            self._log_database_operation(
                "run_sql_file",
                "failed",
                str(sql_path),
                level="ERROR",
                error=self._format_database_error(exc),
            )
            raise
