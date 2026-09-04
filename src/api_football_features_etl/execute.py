"""Run the feature-engineering SQL scripts in filename order."""

import os
from datetime import datetime
from pathlib import Path
from typing import Any, Mapping, Optional, Union

import dotenv

try:
    from .database_conn import PostgresConnector
except ImportError:  # Allow running this file directly from the project root.
    from database_conn import PostgresConnector


DEFAULT_SQL_DIR = Path(__file__).resolve().parent / "static" / "sql"


class FileLogger:
    """Write execution events to one timestamped log file."""

    def __init__(self, log_folder: Union[str, Path] = ".logs") -> None:
        self.log_folder = Path(log_folder).expanduser()
        self.log_file_path: Optional[Path] = None
        self._create_log_file()

    def _create_log_file(self) -> None:
        timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")
        log_path = self.log_folder / f"features-etl-{timestamp}.log"

        try:
            self.log_folder.mkdir(parents=True, exist_ok=True)
            log_path.touch(exist_ok=True)
            self.log_file_path = log_path
        except OSError as exc:
            print(f"[WARNING] Unable to create log file; using terminal: {exc}")

    def log_event(self, level: str, message: Any) -> None:
        timestamp = datetime.now().strftime("%Y%m%d-%H:%M:%S")
        line = f"features-etl-{timestamp} [{str(level).upper()}]: {message}"

        if self.log_file_path is None:
            print(line)
            return

        try:
            with self.log_file_path.open("a", encoding="utf-8") as handle:
                handle.write(line + "\n")
        except OSError as exc:
            self.log_file_path = None
            print(f"[WARNING] Unable to write log file; using terminal: {exc}")
            print(line)


def run_sql_files(
    database_url: Optional[str] = None,
    env_path: Optional[Union[str, Path]] = None,
    echo: bool = False,
    sql_dir: Union[str, Path] = DEFAULT_SQL_DIR,
    params: Optional[Mapping[str, Any]] = None,
    log_folder: Union[str, Path] = ".logs",
) -> list[Path]:
    """Execute every ``.sql`` file in a directory in filename order.

    ``database_url``, ``env_path``, and ``echo`` are passed directly to
    :class:`PostgresConnector`. The optional ``params`` mapping is passed to
    every SQL file for named SQLAlchemy parameters such as ``:league_id``.

    Returns:
        list[Path]: The SQL files that completed successfully.
    """
    logger = FileLogger(log_folder)
    logger.log_event("INFO", "SQL feature execution started")

    try:
        sql_path = Path(sql_dir).expanduser()
        if not sql_path.is_dir():
            raise NotADirectoryError(f"SQL directory not found: {sql_path}")

        sql_files = sorted(sql_path.glob("*.sql"), key=lambda path: path.name)
        if not sql_files:
            raise FileNotFoundError(f"No .sql files found in: {sql_path}")

        logger.log_event("INFO", f"Found {len(sql_files)} SQL file(s) in {sql_path}")
        connector = PostgresConnector(
            database_url=database_url,
            env_path=env_path,
            echo=echo,
            log_event=logger.log_event,
        )

        completed_files = []
        for sql_file in sql_files:
            logger.log_event("INFO", f"Starting SQL file: {sql_file.name}")
            connector.run_sql_file(sql_file, params=params)
            completed_files.append(sql_file)

        logger.log_event(
            "INFO", f"SQL feature execution completed: {len(completed_files)} file(s)"
        )
        return completed_files
    except Exception as exc:
        logger.log_event("ERROR", f"SQL feature execution failed: {exc}")
        raise


def main() -> None:
    dotenv.load_dotenv()

    run_sql_files(
        database_url=os.getenv("DATABASE_URL"),
        env_path=None,
        echo=False,
    )


if __name__ == "__main__":
    main()
