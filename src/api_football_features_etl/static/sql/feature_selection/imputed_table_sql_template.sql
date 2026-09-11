DROP TABLE IF EXISTS {target_table};

CREATE TABLE {target_table} AS
SELECT
    {columns}
FROM {source_table};
