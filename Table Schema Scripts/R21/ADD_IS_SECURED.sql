IF COL_LENGTH('CBDB_REPORTS.LMS.ACCOUNT_MASTER', 'IS_SECURED') IS NULL
BEGIN
	ALTER TABLE CBDB_REPORTS.LMS.ACCOUNT_MASTER
	ADD IS_SECURED BIT
END


