from datetime import datetime
from pathlib import Path
from typing import Any, Optional, Union

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