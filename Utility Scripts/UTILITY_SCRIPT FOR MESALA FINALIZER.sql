SELECT * FROM CBDB_REPORTS.CMN.DATA_COPY_DETAIL
SELECT * FROM CBDB_REPORTS.CMN.DATA_COPY_HEADER
SELECT * FROM CBDB_REPORTS.DMS.ACCOUNT_MASTER
SELECT * FROM CBDB_REPORTS.DMS.ACCT_ANNUAL_BALANCE
SELECT * FROM CBDB_REPORTS.MMS.CLIENT  WHERE HEADER_ID = 93

SELECT * FROM CBDB_REPORTS.RPT.ERROR_DETAILS ORDER BY ID DESC

SELECT * FROM CBDB_STAGE.MMS.ADDRESS
SELECT * FROM CBDB_STAGE.CMN.DATA_COPY_DETAIL
SELECT * FROM CBDB_STAGE.CMN.DATA_COPY_HEADER
SELECT * FROM CBDB_STAGE.DMS.ACCOUNT_ANNUAL_BALANCE
SELECT * FROM CBDB_STAGE.DMS.ACCOUNT_BALANCE_HISTORY

SELECT * FROM CBDB_STAGE.MMS.CLIENT
DELETE FROM CBDB_REPORTS.CMN.DATA_COPY_HEADER WHERE ID = 27
DELETE FROM CBDB_REPORTS.CMN.DATA_COPY_DETAIL WHERE HEADER_ID = 27
--DELETE FROM CBDB_REPORTS.DMS.ACCT_ANNUAL_BALANCE
DELETE FROM CBDB_REPORTS.MMS.CLIENT WHERE HEADER_ID IS NOT NULL

UPDATE CBDB_STAGE.CMN.DATA_COPY_DETAIL SET HEADER_ID = 27 WHERE ID = 7

SELECT * FROM CMN.DATA_COPY_DETAIL

SELECT * FROM CBDB_REPORTS.DMS.ACCOUNT_MASTER

SELECT * FROM DMS.ACCT_ANNUAL_BALANCE


SELECT * FROM CBDB_STAGE.DMS.ACCOUNT_ANNUAL_BALANCE
SELECT * FROM CBDB_STAGE.CMN.DATA_COPY_DETAIL

DECLARE @VAR VARCHAR(MAX) = 'ABCD'
DROP VAR(@VAR)
PRINT @VAR