IF COL_LENGTH('CBDB_REPORTS.DMS.ACCOUNT_MASTER', 'MIN_BAL') IS NULL
BEGIN
	ALTER TABLE CBDB_REPORTS.DMS.ACCOUNT_MASTER
	ADD MIN_BAL DECIMAL(18,2) DEFAULT 0
END