from setuptools import find_packages, setup


setup(
    name="api-football-features-etl",
    version="0.1.0",
    description="features ETL for API-Football ETL",
    package_dir={"": "src"},
    packages=find_packages(where="src"),
    include_package_data=True,
    package_data={"api_football_etl": ["sql/*.sql"]},
    install_requires=[
        "pandas",
        "pyarrow",
        "python-dotenv",
        "requests",
        "SQLAlchemy",
        "sqlparse>=0.5,<1",
        "psycopg2-binary"
    ],
    python_requires=">=3.10",
)