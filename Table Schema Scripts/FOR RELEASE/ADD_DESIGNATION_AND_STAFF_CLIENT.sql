IF COL_LENGTH('CBDB_REPORTS.MMS.CLIENT', 'DESIGNATION') IS NULL
BEGIN
	ALTER TABLE CBDB_REPORTS.MMS.CLIENT
	ADD DESIGNATION NVARCHAR(100)
END

IF COL_LENGTH('CBDB_REPORTS.MMS.CLIENT', 'STAFF') IS NULL
BEGIN
	ALTER TABLE CBDB_REPORTS.MMS.CLIENT
	ADD STAFF BIT
END