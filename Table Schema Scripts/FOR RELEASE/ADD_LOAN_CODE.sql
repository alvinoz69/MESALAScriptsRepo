IF COL_LENGTH('CBDB_REPORTS.LMS.ACCOUNT_MASTER', 'LOAN_CODE') IS NULL
BEGIN
	ALTER TABLE CBDB_REPORTS.LMS.ACCOUNT_MASTER
	ADD LOAN_CODE NVARCHAR(5)
END


