IF COL_LENGTH('CBDB_REPORTS.LMS.ACCOUNT_CO_MAKER', 'CORP_CODE') IS NULL
BEGIN
	ALTER TABLE CBDB_REPORTS.LMS.ACCOUNT_CO_MAKER
	ADD CORP_CODE VARCHAR(50)
END


IF COL_LENGTH('CBDB_REPORTS.LMS.ACCOUNT_CO_MAKER', 'CORP_NAME') IS NULL
BEGIN
	ALTER TABLE CBDB_REPORTS.LMS.ACCOUNT_CO_MAKER
	ADD CORP_NAME VARCHAR(255)
END
