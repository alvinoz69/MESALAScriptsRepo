IF COL_LENGTH('CBDB_REPORTS.DMS.ACCOUNT_MASTER', 'INACTIVITY_DAYS_COUNTER') IS NULL
BEGIN
	ALTER TABLE CBDB_REPORTS.DMS.ACCOUNT_MASTER
	ADD INACTIVITY_DAYS_COUNTER INT
END