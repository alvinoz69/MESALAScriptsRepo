USE CBDB_STAGE
SELECT      
c.name  AS 'ColumnName'
            ,t.name AS 'TableName'
			,sc.name
FROM        sys.columns c
JOIN        sys.tables  t   ON c.object_id = t.object_id
join sys.schemas sc on t.schema_id = sc.schema_id
WHERE       c.name LIKE '%OUTSTANDING%'
ORDER BY    TableName
            ,ColumnName;

SELECT * FROM RPT.REPORT_GENERATOR WHERE FILE_NAME LIKE '%NewLonRel%'

SELECT APPLICATION_DATE,* FROM CBDB_STAGE.MMS.CLIENT
SELECT * FROM CBDB_REPORTS.MMS.CLIENT
SELECT * FROM CBDB_STAGE.MMS.CLIENT_RELATION

SELECT * FROM CBDB_STAGE.LMS.ACCOUNT_INFO