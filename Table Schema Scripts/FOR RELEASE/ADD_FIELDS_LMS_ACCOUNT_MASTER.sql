IF COL_LENGTH('CBDB_REPORTS.LMS.ACCOUNT_MASTER', 'NEXT_AMORT_DATE') IS NULL
BEGIN
	ALTER TABLE CBDB_REPORTS.LMS.ACCOUNT_MASTER
	ADD NEXT_AMORT_DATE DATE
END

IF COL_LENGTH('CBDB_REPORTS.LMS.ACCOUNT_MASTER', 'DEDUCTION_CODE') IS NULL
BEGIN
	ALTER TABLE CBDB_REPORTS.LMS.ACCOUNT_MASTER
	ADD DEDUCTION_CODE NVARCHAR(25)
END

IF COL_LENGTH('CBDB_REPORTS.LMS.ACCOUNT_MASTER', 'DEDUCTION_CODE_DESC') IS NULL
BEGIN
	ALTER TABLE CBDB_REPORTS.LMS.ACCOUNT_MASTER
	ADD DEDUCTION_CODE_DESC NVARCHAR(100)
END