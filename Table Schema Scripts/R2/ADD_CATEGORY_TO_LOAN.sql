IF COL_LENGTH('CBDB_REPORTS.LMS.ACCOUNT_MASTER', 'CATEGORY') IS NULL
BEGIN
	ALTER TABLE CBDB_REPORTS.LMS.ACCOUNT_MASTER
	ADD CATEGORY INT
END
