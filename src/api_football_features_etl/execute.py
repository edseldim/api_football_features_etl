import os
from pathlib import Path
from typing import Any, Optional, Union

import dotenv

from .create_features import CreateFeatures
from .database_conn import PostgresConnector
from .ETLHelper import ETLHelper
from .feature_imputation import FeatureImputation
from .file_logger import FileLogger


DEFAULT_CONFIG_PATH = Path(__file__).resolve().parent / "static" / "config.json"


def run_etl(
    database_url: Optional[str] = None,
    env_path: Optional[Union[str, Path]] = None,
    echo: bool = False,
    config_path: Union[str, Path] = DEFAULT_CONFIG_PATH,
    log_folder: Union[str, Path] = ".logs",
) -> dict[str, Any]:
    """Initialize shared resources once and run every ETL step in order."""
    logger = FileLogger(log_folder)
    logger.log_event("INFO", "Features ETL started")

    try:
        database_connection = PostgresConnector(
            database_url=database_url,
            env_path=env_path,
            echo=echo,
            log_event=logger.log_event,
        )
        etl_helper = ETLHelper(
            database_connection=database_connection,
            logger=logger,
            config_path=config_path,
        )

        create_features = CreateFeatures(etl_helper)
        feature_selection = FeatureImputation(etl_helper)

        created_features = create_features.run()
        selected_features = feature_selection.run()
        result = {
            "created_features": created_features,
            "feature_selection": selected_features,
        }

        logger.log_event("INFO", "Features ETL completed")
        return result
    except Exception as exc:
        logger.log_event("ERROR", f"Features ETL failed: {exc}")
        raise


def main() -> None:
    """Load environment variables and execute the ETL pipeline."""
    dotenv.load_dotenv()
    run_etl(database_url=os.getenv("DATABASE_URL"))


if __name__ == "__main__":
    main()
