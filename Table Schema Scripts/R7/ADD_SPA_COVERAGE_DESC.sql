IF COL_LENGTH('CBDB_REPORTS.MMS.CLIENT', 'SPA_COVERAGE_DESC') IS NULL
BEGIN
	ALTER TABLE CBDB_REPORTS.MMS.CLIENT
	ADD SPA_COVERAGE_DESC VARCHAR(200)
END
