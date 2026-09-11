"""Shared dependencies and configuration for ETL steps."""

import json
from pathlib import Path
from typing import Any, Union

from .database_conn import PostgresConnector
from .file_logger import FileLogger


DEFAULT_SQL_DIR = Path(__file__).resolve().parent / "static" / "sql"


class ETLHelper:
    """Hold resources initialized once and shared by every ETL step."""

    DEFAULT_SQL_DIR = DEFAULT_SQL_DIR

    def __init__(
        self,
        database_connection: PostgresConnector,
        logger: FileLogger,
        config_path: Union[str, Path],
    ) -> None:
        """Store shared services and load a JSON object as ETL parameters.

        Parameters:
            database_connection: Initialized PostgreSQL connector.
            logger: Initialized file logger.
            config_path: Path to a JSON file whose root value is an object.

        Raises:
            TypeError: If ``config_path`` is not a string or Path, or if the
                decoded JSON root is not an object.
            ValueError: If ``config_path`` is empty or is not a ``.json`` file.
            FileNotFoundError: If the configuration file does not exist.
            json.JSONDecodeError: If the configuration contains invalid JSON.
        """
        self.database_connection = database_connection
        self.logger = logger
        self.params = self._load_params(config_path)
        self.sql_path = self.DEFAULT_SQL_DIR

    @staticmethod
    def _load_params(config_path: Union[str, Path]) -> dict[str, Any]:
        """Read and validate the ETL parameter dictionary."""
        if not isinstance(config_path, (str, Path)):
            raise TypeError("config_path must be a string or Path")

        config_path_text = str(config_path)
        if not config_path_text:
            raise ValueError("config_path must not be empty")

        path = Path(config_path_text).expanduser()
        if path.suffix.lower() != ".json":
            raise ValueError("config_path must have a .json extension")
        if not path.is_file():
            raise FileNotFoundError(f"Configuration file not found: {path}")

        with path.open(encoding="utf-8") as config_file:
            params = json.load(config_file)

        if not isinstance(params, dict):
            raise TypeError("The JSON configuration root must be an object")

        return params
