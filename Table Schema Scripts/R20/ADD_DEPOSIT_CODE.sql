IF COL_LENGTH('CBDB_REPORTS.DMS.ACCOUNT_MASTER', 'DEPOSIT_CODE') IS NULL
BEGIN
	ALTER TABLE CBDB_REPORTS.DMS.ACCOUNT_MASTER
	ADD DEPOSIT_CODE NVARCHAR(5)
END