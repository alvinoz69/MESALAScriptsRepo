IF COL_LENGTH('CBDB_REPORTS.LMS.ACCT_BAL_HISTORY', 'TRAN_TYPE') IS NULL
BEGIN
	ALTER TABLE CBDB_REPORTS.LMS.ACCT_BAL_HISTORY
	ADD TRAN_TYPE SMALLINT
END