IF COL_LENGTH('CBDB_REPORTS.MMS.CLIENT', 'DIVISION_CODE') IS NULL
BEGIN
	ALTER TABLE CBDB_REPORTS.MMS.CLIENT
	ADD DIVISION_CODE VARCHAR(15)
END