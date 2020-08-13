IF COL_LENGTH('CBDB_REPORTS.MMS.CLIENT', 'RISK_CATEGORY_CODE') IS NULL
BEGIN
	ALTER TABLE CBDB_REPORTS.MMS.CLIENT
	ADD RISK_CATEGORY_CODE NVARCHAR(6)
END

IF COL_LENGTH('CBDB_REPORTS.MMS.CLIENT', 'RISK_CATEGORY_DESC') IS NULL
BEGIN
	ALTER TABLE CBDB_REPORTS.MMS.CLIENT
	ADD RISK_CATEGORY_DESC NVARCHAR(30)
END