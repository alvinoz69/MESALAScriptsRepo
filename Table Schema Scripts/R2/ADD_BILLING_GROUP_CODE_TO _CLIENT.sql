IF COL_LENGTH('CBDB_REPORTS.MMS.CLIENT', 'BILLING_GROUP_CODE') IS NULL
BEGIN
	ALTER TABLE CBDB_REPORTS.MMS.CLIENT
	ADD BILLING_GROUP_CODE NVARCHAR(8) NULL
END
