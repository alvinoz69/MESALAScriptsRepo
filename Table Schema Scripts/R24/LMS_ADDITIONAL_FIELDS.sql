IF COL_LENGTH('CBDB_REPORTS.LMS.APPRAISAL', 'REPA_STATUS_DESC') IS NULL
BEGIN
	ALTER TABLE CBDB_REPORTS.LMS.APPRAISAL
	ADD REPA_STATUS_DESC NVARCHAR(100)
END

IF COL_LENGTH('CBDB_REPORTS.LMS.INSURANCE', 'PAYMENT_TYPE_DESC') IS NULL
BEGIN
	ALTER TABLE CBDB_REPORTS.LMS.INSURANCE
	ADD PAYMENT_TYPE_DESC NVARCHAR(100)
END

IF COL_LENGTH('CBDB_REPORTS.LMS.ACCOUNT_MASTER', 'IS_STAGGERED') IS NULL
BEGIN
	ALTER TABLE CBDB_REPORTS.LMS.ACCOUNT_MASTER
	ADD IS_STAGGERED BIT
END

IF COL_LENGTH('CBDB_REPORTS.LMS.ACCOUNT_MASTER', 'IS_REAL_ESTATE') IS NULL
BEGIN
	ALTER TABLE CBDB_REPORTS.LMS.ACCOUNT_MASTER
	ADD IS_REAL_ESTATE BIT
END

IF COL_LENGTH('CBDB_REPORTS.LMS.ACCOUNT_MASTER', 'FIRST_RELEASE_DATE') IS NULL
BEGIN
	ALTER TABLE CBDB_REPORTS.LMS.ACCOUNT_MASTER
	ADD FIRST_RELEASE_DATE DATE
END