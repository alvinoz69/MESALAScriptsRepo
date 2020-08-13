SELECT 'IF COL_LENGTH(''CBDB_STAGE.' + TABLE_SCHEMA + '.' + TABLE_NAME + ''', ''' + COLUMN_NAME + ''') IS NOT NULL BEGIN ' + 
+ 'ALTER TABLE CBDB_STAGE.' + TABLE_SCHEMA + '.' + TABLE_NAME
+ ' ALTER COLUMN ' + COLUMN_NAME + ' NVARCHAR(' + CAST(CHARACTER_MAXIMUM_LENGTH AS varchar(MAX)) + ') END'
,table_name [Table Name], column_name [Column Name], TABLE_SCHEMA, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH
FROM information_schema.columns where data_type = 'Nchar'